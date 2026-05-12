import { commonEventManager } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConstants } from '../constants/AppConstants';

const DOMAIN: number = 0xCE01;
const TAG: string = 'CommonEventService';

export type SystemEventListener = (event: string, data: commonEventManager.CommonEventData) => void;

// Thin wrapper around BasicServicesKit's commonEventManager. Subscribes to the
// system events the codelab cares about (battery low / power connected /
// connectivity change) and exposes a passthrough publish() for app-level
// events. Other services register a SystemEventListener to react.
export class CommonEventService {
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;
  private listeners: SystemEventListener[] = [];
  private initialized: boolean = false;

  init(): Promise<void> {
    if (this.initialized) {
      return Promise.resolve();
    }
    const info: commonEventManager.CommonEventSubscribeInfo = {
      events: [
        commonEventManager.Support.COMMON_EVENT_BATTERY_LOW,
        commonEventManager.Support.COMMON_EVENT_POWER_CONNECTED,
        commonEventManager.Support.COMMON_EVENT_CONNECTIVITY_CHANGE
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

  // Demonstrates the publish side of the pub/sub backbone with
  // CommonEventPublishData. Used by AudioPlayerService when an episode ends.
  publish(eventName: string, detail: string): void {
    const data: commonEventManager.CommonEventPublishData = {
      bundleName: AppConstants.BUNDLE_NAME,
      data: detail
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

  addSystemListener(listener: SystemEventListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  removeSystemListener(listener: SystemEventListener): void {
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
    const name: string = data.event;
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i](name, data);
    }
  }
}

export const commonEventService: CommonEventService = new CommonEventService();
