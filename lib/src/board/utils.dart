int getKing(bool p1) => p1 ? 28 : 4;
int getQueen(bool p1) => p1 ? 27 : 3;
List<int> getBishops(bool p1) => p1 ? <int>[26, 29] : <int>[2, 5];
List<int> getKnights(bool p1) => p1 ? <int>[25, 30] : <int>[1, 6];
List<int> getRooks(bool p1) => p1 ? <int>[24, 31] : <int>[0, 7];
List<int> getRange(bool p1) =>
    List<int>.generate(16, (i) => p1 ? i + 16 : i, growable: false);
List<int> getRangeStart(bool p1) =>
    List<int>.generate(8, (i) => p1 ? i + 24 : i, growable: false);
List<int> getRangePawn(bool p1) =>
    List<int>.generate(8, (i) => p1 ? i + 16 : i + 8, growable: false);
bool belongsTo(int id, bool p1) => p1 ? id >= 16 : id < 16;
bool getInversePlayer(bool p1) => !p1;
bool isIDValid(int id) => id >= 0 && id <= 31;
