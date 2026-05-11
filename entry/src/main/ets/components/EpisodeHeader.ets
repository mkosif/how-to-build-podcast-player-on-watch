@Component
export struct EpisodeHeader {
  @Prop podcast: string = '';
  @Prop title: string = '';
  @Prop artworkLabel: string = '';

  build() {
    Column({ space: 6 }) {
      Stack() {
        Circle({ width: 56, height: 56 })
          .fill('#1F6FEB')
          .opacity(0.18);
        Text(this.artworkLabel)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F6FEB');
      }
      .width(56)
      .height(56);

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
