@Component
export struct EpisodeHeader {
  @Prop podcast: string = '';
  @Prop title: string = '';

  build() {
    Column({ space: 4 }) {
      Text(this.podcast)
        .fontSize(11)
        .fontColor('#7A8595')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });

      Text(this.title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#0E1116')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center);
  }
}
