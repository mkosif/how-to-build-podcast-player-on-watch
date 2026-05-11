import { MainPlayerView } from '../components/MainPlayerView';

@Entry
@Component
struct Index {
  build() {
    Column() {
      MainPlayerView();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}
