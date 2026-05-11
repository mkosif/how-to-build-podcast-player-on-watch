import { PlaybackEvent } from '../model/PlaybackEvent';
import { TimeFormatter } from '../utils/TimeFormatter';

@Component
export struct EventLogList {
  @Prop events: PlaybackEvent[] = [];

  build() {
    if (this.events.length === 0) {
      Column() {
        Text('No events yet')
          .fontSize(12)
          .fontColor('#7A8595');
        Text('Trigger an action to see CommonEventData arrive')
          .fontSize(10)
          .fontColor('#9AA3B0')
          .textAlign(TextAlign.Center)
          .margin({ top: 4 });
      }
      .width('100%')
      .padding(12)
      .alignItems(HorizontalAlign.Center);
    } else {
      List({ space: 6 }) {
        ForEach(this.events, (item: PlaybackEvent) => {
          ListItem() {
            this.row(item);
          }
        }, (item: PlaybackEvent) => item.id);
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 8, right: 8 })
      .scrollBar(BarState.Off);
    }
  }

  @Builder
  row(item: PlaybackEvent) {
    Column({ space: 2 }) {
      Row() {
        Text(item.shortName())
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#0E1116')
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
        Text(TimeFormatter.formatClock(item.timestampMs))
          .fontSize(9)
          .fontColor('#9AA3B0');
      }
      .width('100%');

      if (item.detail.length > 0) {
        Text(item.detail)
          .fontSize(10)
          .fontColor('#5A6472')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
    }
    .width('100%')
    .padding(8)
    .borderRadius(10)
    .backgroundColor('#F5F7FA')
    .alignItems(HorizontalAlign.Start);
  }
}
