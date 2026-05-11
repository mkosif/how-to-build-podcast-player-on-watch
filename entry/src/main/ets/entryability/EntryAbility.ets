import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { commonEventService } from '../services/CommonEventService';
import { audioPlayerService } from '../services/AudioPlayerService';
import { metadataService } from '../services/MetadataService';
import { soundEffectService } from '../services/SoundEffectService';
import { connectivityService } from '../services/ConnectivityService';

const DOMAIN: number = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    audioPlayerService.bind(this.context);
    metadataService.bind(this.context);
    soundEffectService.bind(this.context);

    audioPlayerService.attachSystemListener();
    connectivityService.attachSystemListener();

    commonEventService.init().catch((err: Object) => {
      hilog.error(DOMAIN, 'testTag', 'CommonEventService init rejected: %{public}s', JSON.stringify(err));
    });
    soundEffectService.init().catch((err: Object) => {
      hilog.error(DOMAIN, 'testTag', 'SoundEffectService init rejected: %{public}s', JSON.stringify(err));
    });
    connectivityService.queryInitial();
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
    connectivityService.release();
    audioPlayerService.release().catch((err: Object) => {
      hilog.error(DOMAIN, 'testTag', 'AudioPlayerService release rejected: %{public}s', JSON.stringify(err));
    });
    soundEffectService.release().catch((err: Object) => {
      hilog.error(DOMAIN, 'testTag', 'SoundEffectService release rejected: %{public}s', JSON.stringify(err));
    });
    commonEventService.release();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
