// FieldValue.increment
//=======================
//    Firestore.instance
//        .collection('userInfoList')
//        .document(document)
//        .updateData(<String, dynamic>{
//      'like': FieldValue.increment(1),
//    });
//=======================

// FireStore Transaction
// ================================
//var documentReference = Firestore.instance
//    .collection('messages')
//    .document(groupChatId)
//    .collection(groupChatId)
//    .document(DateTime.now().millisecondsSinceEpoch.toString());
//Firestore.instance.runTransaction((transaction) async {
//await transaction.set(documentReference, obj);
//});
// =================================