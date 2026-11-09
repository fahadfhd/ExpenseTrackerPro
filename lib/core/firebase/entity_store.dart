import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kept/core/firebase/firebase_providers.dart';

typedef FromMap<T> = T Function(String id, Map<String, dynamic> map);

/// Thin typed wrapper over one `users/{uid}/{collection}`.
///
/// Writes go through [WriteDispatcher] and return immediately: Firestore
/// applies them to the local cache (so streams update at once, also offline)
/// and syncs in the background.
class EntityStore<T> {
  EntityStore({
    required this.userDoc,
    required this.collection,
    required this.fromMap,
    required this.writer,
  });

  final DocumentReference<Map<String, dynamic>> userDoc;
  final String collection;
  final FromMap<T> fromMap;
  final WriteDispatcher writer;

  CollectionReference<Map<String, dynamic>> get ref =>
      userDoc.collection(collection);

  FirebaseFirestore get firestore => userDoc.firestore;

  /// Generated locally, so it works offline and never collides.
  String newId() => ref.doc().id;

  List<T> _decode(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs.map((d) => fromMap(d.id, d.data())).toList();

  Stream<List<T>> watchAll() => ref.snapshots().map(_decode);

  Stream<List<T>> watchQuery(
    Query<Map<String, dynamic>> Function(
      CollectionReference<Map<String, dynamic>>,
    )
    build,
  ) => build(ref).snapshots().map(_decode);

  Stream<T?> watchOne(String id) => ref
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? fromMap(s.id, s.data()!) : null);

  Future<List<T>> fetchAll() async => _decode(await ref.get());

  void set(String id, Map<String, dynamic> data, {bool merge = false}) =>
      writer.dispatch(ref.doc(id).set(data, SetOptions(merge: merge)));

  void delete(String id) => writer.dispatch(ref.doc(id).delete());
}
