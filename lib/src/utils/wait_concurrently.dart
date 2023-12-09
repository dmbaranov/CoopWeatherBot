Future<(T1, T2, T3)> waitConcurrently3<T1, T2, T3>(
  Future<T1> future1,
  Future<T2> future2,
  Future<T3> future3,
) async {
  late T1 result1;
  late T2 result2;
  late T3 result3;

  await Future.wait(
      [future1.then((value) => result1 = value), future2.then((value) => result2 = value), future3.then((value) => result3 = value)]);

  return Future.value((result1, result2, result3));
}
