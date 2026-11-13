// 序号严格采用用户于2026-11-05提供的现场清单。
class StationConfig {
  const StationConfig(this.number, this.code, {this.area = '创新大厦旁'});
  final int number;
  final String code;
  final String area;
}

const knownStations = [
  StationConfig(1, '2TH00016899'),
  StationConfig(2, '2TH00016900'),
  StationConfig(3, '2TH00016902'),
  StationConfig(4, '2TH00016934'),
  StationConfig(5, '2TH00016933'),
  StationConfig(6, '2TH00016906'),
  StationConfig(7, '2TH00016893'),
  StationConfig(8, '2TH00016904'),
  StationConfig(9, '2TH00016894'),
  StationConfig(10, '2TH00016897'),
  StationConfig(11, '2TH00016903'),
  StationConfig(12, '2TH00016895'),
  StationConfig(13, '2TH00016898'),
  StationConfig(14, '2TH00016907'),
  StationConfig(15, '2TH00016909'),
  StationConfig(16, '2TH00016890'),
  StationConfig(17, '2TH00016896'),
  StationConfig(18, '2TH00016901'),
  StationConfig(19, '2TH00016908'),
  StationConfig(20, '2TH00016905'),
];

// 兰亭编号来自原参考项目的 areas.dart；现场位置尚未绘制。
const lantingStations = [
  StationConfig(1, '4GR00007971', area: '兰亭'),
  StationConfig(2, '4GR00008013', area: '兰亭'),
  StationConfig(3, '4GR00007975', area: '兰亭'),
  StationConfig(4, '4GR00007977', area: '兰亭'),
  StationConfig(5, '4GR00007978', area: '兰亭'),
  StationConfig(6, '4GR00008016', area: '兰亭'),
  StationConfig(7, '4GR00007974', area: '兰亭'),
  StationConfig(8, '4GR00007996', area: '兰亭'),
  StationConfig(9, '4GR00008014', area: '兰亭'),
  StationConfig(10, '4GR00007994', area: '兰亭'),
  StationConfig(11, '4GR00007992', area: '兰亭'),
  StationConfig(12, '4GR00007973', area: '兰亭'),
];
// 二餐与行政楼：沿用原参考项目设备清单及顺序，地图待现场确认。
const diningStations = [
  StationConfig(1, '4GR00009820', area: '二餐'),
  StationConfig(2, '4GR00009377', area: '二餐'),
  StationConfig(3, '4GR00009460', area: '二餐'),
  StationConfig(4, '4GR00009456', area: '二餐'),
  StationConfig(5, '4GR00009381', area: '二餐'),
  StationConfig(6, '4GR00009366', area: '二餐'),
];
const administrationStations = [
  StationConfig(1, '4GR00009364', area: '行政楼'),
  StationConfig(2, '4GR00009822', area: '行政楼'),
];
const stationAreas = {
  '创新大厦旁': knownStations,
  '兰亭': lantingStations,
  '二餐': diningStations,
  '行政楼': administrationStations,
};
