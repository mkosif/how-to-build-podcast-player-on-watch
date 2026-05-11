@Component
export struct PlayerControls {
  @Prop isPlaying: boolean = false;
  onTogglePlay: () => void = () => {};
  onSkipBack: () => void = () => {};
  onSkipForward: () => void = () => {};

  build() {
    Row({ space: 14 }) {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('⏮')
          .fontSize(18)
          .fontColor('#0E1116');
      }
      .width(40)
      .height(40)
      .backgroundColor('#EEF1F5')
      .onClick(() => this.onSkipBack());

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text(this.isPlaying ? '⏸' : '▶')
          .fontSize(22)
          .fontColor('#FFFFFF');
      }
      .width(56)
      .height(56)
      .backgroundColor('#1F6FEB')
      .onClick(() => this.onTogglePlay());

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('⏭')
          .fontSize(18)
          .fontColor('#0E1116');
      }
      .width(40)
      .height(40)
      .backgroundColor('#EEF1F5')
      .onClick(() => this.onSkipForward());
    }
    .justifyContent(FlexAlign.Center)
    .width('100%');
  }
}
