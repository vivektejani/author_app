import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../global.dart';
import '../helpers/cloud_firestore_helper.dart';

class AddEditPage extends StatefulWidget {
  const AddEditPage({Key? key}) : super(key: key);

  @override
  State<AddEditPage> createState() => _AddEditPageState();
}

class _AddEditPageState extends State<AddEditPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController authorController = TextEditingController();
  final TextEditingController bookController = TextEditingController();

  String? author;
  String? book;

  Uint8List? image;
  Uint8List? decodedImage;
  String imageString = "";
  bool isNew = false;

  @override
  void initState() {
    super.initState();
    clearControllersAndVar();
  }

  @override
  Widget build(BuildContext context) {
    QueryDocumentSnapshot? res;
    if (isUpdate) {
      res = ModalRoute.of(context)!.settings.arguments as QueryDocumentSnapshot;

      authorController.text = "${res["author"]}";
      bookController.text = "${res["book"]}";

      isNew == false ? image = base64Decode(res["image"]) : null;
    }
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () async {
              if (image != null) {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  imageString = base64Encode(image!);

                  Map<String, dynamic> data = {
                    "author": author,
                    "book": book,
                    "image": imageString
                  };

                  if (isUpdate) {
                    await CloudFirestoreHelper.cloudFirestoreHelper
                        .updateRecords(data: data, id: res!.id);
                  } else {
                    await CloudFirestoreHelper.cloudFirestoreHelper
                        .insertData(data: data);
                  }

                  Navigator.of(context).pop();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                    content: Text(
                      "Add image First..",
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }
            },
            child: Text(
              (isUpdate) ? "SAVE" : "ADD",
              style: GoogleFonts.lato(
                color: Colors.white.withOpacity(0.9),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 7),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        height: 220,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(13),
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: image != null
                                ? MemoryImage(
                                    image!,
                                  )
                                : const NetworkImage(
                                    "https://cdn.newsapi.com.au/image/v1/8791f511b22d3b0abb8b52c575bff083?width=650",
                                  ) as ImageProvider,
                          ),
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      mini: true,
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        XFile? pickImage =
                            await picker.pickImage(source: ImageSource.gallery);

                        if (pickImage != null) {
                          File compressedImage =
                              await FlutterNativeImage.compressImage(
                                  pickImage.path);
                          image = await compressedImage.readAsBytes();
                          isNew = true;
                          imageString = base64Encode(image!);
                        }
                        setState(() {});
                      },
                      child: Icon(
                        (isUpdate) ? Icons.edit : Icons.add,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Text(
                  "Author",
                  style: GoogleFonts.lato(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  style: GoogleFonts.lato(),
                  controller: authorController,
                  decoration: textFieldDecoration("Author name"),
                  onSaved: (val) {
                    author = val;
                  },
                  validator: (val) =>
                      (val!.isEmpty) ? "Enter Author Name First..." : null,
                ),
                const SizedBox(height: 20),
                Text(
                  "Book",
                  style: GoogleFonts.lato(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  style: GoogleFonts.lato(),
                  controller: bookController,
                  decoration: textFieldDecoration("Book name"),
                  onSaved: (val) {
                    book = val;
                  },
                  validator: (val) =>
                      (val!.isEmpty) ? "Enter Book Name First..." : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  textFieldDecoration(String hint) {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
      hintText: hint,
    );
  }

  clearControllersAndVar() {
    authorController.clear();
    bookController.clear();

    author = null;
    image = null;
    book = null;
  }
}
