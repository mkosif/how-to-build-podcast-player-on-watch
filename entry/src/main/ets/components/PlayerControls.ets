@Component
export struct PlayerControls {
  @Prop isPlaying: boolean = false;
  @Prop isReady: boolean = false;
  onTogglePlay: () => void = () => {};
  onSkipBack: () => void = () => {};
  onSkipForward: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      TransportButton({
        icon: $r('app.media.ic_skip_back'),
        btnSize: 44,
        iconSize: 26,
        bgColor: '#EEF1F5',
        shadowColor: '#1A000000',
        onTap: () => this.onSkipBack()
      });

      TransportButton({
        icon: this.isPlaying ? $r('app.media.ic_pause') : $r('app.media.ic_play'),
        btnSize: 62,
        iconSize: 28,
        bgColor: '#1F6FEB',
        shadowColor: '#331F6FEB',
        opacityValue: this.isReady ? 1 : 0.5,
        onTap: () => this.onTogglePlay()
      });

      TransportButton({
        icon: $r('app.media.ic_skip_forward'),
        btnSize: 44,
        iconSize: 26,
        bgColor: '#EEF1F5',
        shadowColor: '#1A000000',
        onTap: () => this.onSkipForward()
      });
    }
    .justifyContent(FlexAlign.Center)
    .width('100%');
  }
}

@Component
struct TransportButton {
  @Prop icon: Resource = $r('app.media.ic_play');
  @Prop btnSize: number = 44;
  @Prop iconSize: number = 24;
  @Prop bgColor: string = '#EEF1F5';
  @Prop shadowColor: string = '#1A000000';
  @Prop opacityValue: number = 1;
  onTap: () => void = () => {};

  build() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      Image(this.icon)
        .width(this.iconSize)
        .height(this.iconSize)
        .objectFit(ImageFit.Contain);
    }
    .width(this.btnSize)
    .height(this.btnSize)
    .backgroundColor(this.bgColor)
    .opacity(this.opacityValue)
    .shadow({
      radius: this.btnSize > 50 ? 10 : 6,
      color: this.shadowColor,
      offsetY: this.btnSize > 50 ? 2 : 1
    })
    .onClick(() => this.onTap());
  }
}
