@Component
export struct StatusPill {
  @Prop label: string = '';
  @Prop tone: string = 'info';

  private bgFor(tone: string): string {
    if (tone === 'warn') {
      return '#FFE9C7';
    }
    if (tone === 'good') {
      return '#D5F2DD';
    }
    return '#E6EEFC';
  }

  private fgFor(tone: string): string {
    if (tone === 'warn') {
      return '#7A4A00';
    }
    if (tone === 'good') {
      return '#1B6A33';
    }
    return '#1F4FB1';
  }

  build() {
    Text(this.label)
      .fontSize(10)
      .fontColor(this.fgFor(this.tone))
      .backgroundColor(this.bgFor(this.tone))
      .borderRadius(10)
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis });
  }
}
