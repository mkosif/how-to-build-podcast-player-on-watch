import { commonEventManager } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConstants } from '../constants/AppConstants';
import { PlaybackEvent } from '../model/PlaybackEvent';

const DOMAIN: number = 0xCE01;
const TAG: string = 'CommonEventService';

export type EventListener = (event: PlaybackEvent) => void;

// All BasicServicesKit common-event traffic for this app flows through this
// service: subscribe, publish, unsubscribe, plus a tiny in-process fan-out so
// multiple ArkUI components can react without each opening their own subscriber.
export class CommonEventService {
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;
  private listeners: EventListener[] = [];
  private nextEventId: number = 1;
  private initialized: boolean = false;
  private eventLog: PlaybackEvent[] = [];

  isReady(): boolean {
    return this.initialized && this.subscriber !== null;
  }

  // Returns a defensive copy so ArkUI @State change detection sees a new array.
  snapshotLog(): PlaybackEvent[] {
    return this.eventLog.slice();
  }

  init(): Promise<void> {
    if (this.initialized) {
      return Promise.resolve();
    }
    const info: commonEventManager.CommonEventSubscribeInfo = {
      events: [
        AppConstants.EVENT_PLAYBACK_STARTED,
        AppConstants.EVENT_PLAYBACK_PAUSED,
        AppConstants.EVENT_EPISODE_SKIPPED,
        AppConstants.EVENT_EPISODE_COMPLETED,
        AppConstants.EVENT_CACHE_READY,
        AppConstants.EVENT_LOW_BATTERY,
        AppConstants.EVENT_CELLULAR_READY,
        commonEventManager.Support.COMMON_EVENT_BATTERY_LOW,
        commonEventManager.Support.COMMON_EVENT_POWER_CONNECTED
      ]
    };
    return new Promise<void>((resolve: () => void) => {
      try {
        commonEventManager.createSubscriber(info,
          (createErr: BusinessError, subscriber: commonEventManager.CommonEventSubscriber) => {
            if (createErr) {
              hilog.error(DOMAIN, TAG, 'createSubscriber failed: %{public}s', JSON.stringify(createErr));
              resolve();
              return;
            }
            this.subscriber = subscriber;
            this.attachSubscribe();
            this.initialized = true;
            resolve();
          });
      } catch (err) {
        hilog.error(DOMAIN, TAG, 'createSubscriber threw: %{public}s', JSON.stringify(err));
        resolve();
      }
    });
  }

  publish(eventName: string, detail: string): void {
    const params: Record<string, Object> = { 'detail': detail };
    const data: commonEventManager.CommonEventPublishData = {
      bundleName: AppConstants.BUNDLE_NAME,
      data: detail,
      parameters: params
    };
    try {
      commonEventManager.publish(eventName, data, (err: BusinessError) => {
        if (err) {
          hilog.error(DOMAIN, TAG, 'publish %{public}s failed: %{public}s', eventName, JSON.stringify(err));
        }
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'publish threw: %{public}s', JSON.stringify(err));
    }
  }

  addListener(listener: EventListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  removeListener(listener: EventListener): void {
    const idx: number = this.listeners.indexOf(listener);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
    }
  }

  release(): void {
    const sub: commonEventManager.CommonEventSubscriber | null = this.subscriber;
    if (sub !== null) {
      try {
        commonEventManager.unsubscribe(sub, (err: BusinessError) => {
          if (err) {
            hilog.error(DOMAIN, TAG, 'unsubscribe failed: %{public}s', JSON.stringify(err));
          }
        });
      } catch (err) {
        hilog.error(DOMAIN, TAG, 'unsubscribe threw: %{public}s', JSON.stringify(err));
      }
    }
    this.subscriber = null;
    this.listeners = [];
    this.eventLog = [];
    this.initialized = false;
  }

  private attachSubscribe(): void {
    const sub: commonEventManager.CommonEventSubscriber | null = this.subscriber;
    if (sub === null) {
      return;
    }
    try {
      commonEventManager.subscribe(sub,
        (subErr: BusinessError, data: commonEventManager.CommonEventData) => {
          if (subErr) {
            hilog.error(DOMAIN, TAG, 'subscribe callback err: %{public}s', JSON.stringify(subErr));
            return;
          }
          this.dispatch(data);
        });
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'subscribe threw: %{public}s', JSON.stringify(err));
    }
  }

  private dispatch(data: commonEventManager.CommonEventData): void {
    const name: string = data.event !== undefined ? data.event : 'unknown';
    const detail: string = this.extractDetail(data);
    const playback: PlaybackEvent = new PlaybackEvent(
      `evt-${this.nextEventId}`,
      name,
      detail,
      Date.now()
    );
    this.nextEventId = this.nextEventId + 1;
    this.eventLog.unshift(playback);
    if (this.eventLog.length > AppConstants.MAX_LOG_SIZE) {
      this.eventLog.length = AppConstants.MAX_LOG_SIZE;
    }
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i](playback);
    }
  }

  private extractDetail(data: commonEventManager.CommonEventData): string {
    if (data.data !== undefined && data.data.length > 0) {
      return data.data;
    }
    const params: Record<string, Object> | undefined = data.parameters;
    if (params !== undefined) {
      const v: Object | undefined = params['detail'];
      if (v !== undefined) {
        return `${v}`;
      }
    }
    return '';
  }
}

export const commonEventService: CommonEventService = new CommonEventService();
