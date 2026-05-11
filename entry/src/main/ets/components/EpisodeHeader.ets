@Component
export struct EpisodeHeader {
  @Prop exampleLabel: string = '';
  @Prop title: string = '';
  @Prop apiLabel: string = '';

  build() {
    Column({ space: 3 }) {
      Text(this.exampleLabel)
        .fontSize(9)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F6FEB')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });

      Text(this.title)
        .fontSize(10)
        .fontColor('#7A8595')
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });

      Text(this.apiLabel)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#0E1116')
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center);
  }
}
