import { connection } from '@kit.NetworkKit';
import { commonEventManager } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConstants } from '../constants/AppConstants';
import { audioPlayerService } from './AudioPlayerService';
import { commonEventService, SystemEventListener } from './CommonEventService';

const DOMAIN: number = 0xCE05;
const TAG: string = 'ConnectivityService';

// Listens for the system COMMON_EVENT_CONNECTIVITY_CHANGE and translates the
// active bearer (Wi-Fi vs cellular) into a buffer hint for AudioPlayerService,
// implementing the spec's "adaptive streaming for cellular-connected watches".
export class ConnectivityService {
  private listener: SystemEventListener = (event: string, _data: commonEventManager.CommonEventData) => {
    if (event === commonEventManager.Support.COMMON_EVENT_CONNECTIVITY_CHANGE) {
      this.applyBearerStrategy();
    }
  };

  attachSystemListener(): void {
    commonEventService.addSystemListener(this.listener);
  }

  queryInitial(): void {
    this.applyBearerStrategy();
  }

  release(): void {
    commonEventService.removeSystemListener(this.listener);
  }

  private applyBearerStrategy(): void {
    try {
      const handle: connection.NetHandle = connection.getDefaultNetSync();
      if (handle.netId === 0) {
        audioPlayerService.setBufferDuration(AppConstants.URL_STREAM_BUFFER_WIFI_SEC);
        return;
      }
      const cap: connection.NetCapabilities = connection.getNetCapabilitiesSync(handle);
      if (cap.bearerTypes.indexOf(connection.NetBearType.BEARER_CELLULAR) >= 0) {
        audioPlayerService.setBufferDuration(AppConstants.URL_STREAM_BUFFER_CELLULAR_SEC);
      } else {
        audioPlayerService.setBufferDuration(AppConstants.URL_STREAM_BUFFER_WIFI_SEC);
      }
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'bearer query failed: %{public}s', JSON.stringify(err));
    }
  }
}

export const connectivityService: ConnectivityService = new ConnectivityService();
