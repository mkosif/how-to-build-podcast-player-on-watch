import { commonEventService, EventListener } from '../services/CommonEventService';
import { PlaybackEvent } from '../model/PlaybackEvent';
import { EventLogList } from '../components/EventLogList';

@Component
export struct EventMonitorPage {
  @State events: PlaybackEvent[] = [];

  private listener: EventListener = (_event: PlaybackEvent) => {
    this.events = commonEventService.snapshotLog();
  };

  aboutToAppear(): void {
    this.events = commonEventService.snapshotLog();
    commonEventService.addListener(this.listener);
  }

  aboutToDisappear(): void {
    commonEventService.removeListener(this.listener);
  }

  build() {
    NavDestination() {
      Column() {
        Text('Event Monitor')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#0E1116')
          .margin({ top: 8, bottom: 6 });

        Text(`${this.events.length} record${this.events.length === 1 ? '' : 's'}`)
          .fontSize(10)
          .fontColor('#7A8595')
          .margin({ bottom: 8 });

        EventLogList({ events: this.events });
      }
      .width('100%')
      .height('100%')
      .padding({ left: 6, right: 6, bottom: 8 });
    }
    .hideTitleBar(true)
    .backgroundColor('#FFFFFF');
  }
}
