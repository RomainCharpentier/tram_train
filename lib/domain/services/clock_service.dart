abstract class ClockService {
  DateTime now();
}

class SystemClockService implements ClockService {
  @override
  DateTime now() => DateTime.now();
}

class MockClockService implements ClockService {
  final DateTime _fixedTime;

  MockClockService(this._fixedTime);

  @override
  DateTime now() => _fixedTime;
}






