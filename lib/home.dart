import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:store/viewproduct.dart';
class SmallStore extends StatefulWidget {
  const SmallStore({super.key});

  @override
  State<SmallStore> createState() => _SmallStoreState();
}

class _SmallStoreState extends State<SmallStore> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final productName = _nameController.text;
    final productDescription = _descriptionController.text;
    final price = _priceController.text;

    if (productName.isEmpty || productDescription.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
        ),
      );
      return;
    }


    await FirebaseFirestore.instance.collection('products').add({
      'name': productName,
      'description': productDescription,
      'price': price,
      'image': _profileImage != null ? await uploadImage(_profileImage!) : null,
    });

    // Show confirmation message
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      SnackBar(
        content: Text('Product saved successfully!'),
      ),
    );

    // Clear the inputs
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    setState(() {
      _profileImage = null;
    });
  }

  Future<String?> uploadImage(File image) async {
    try {
      String fileName = basename(image.path);
      Reference storageReference =
      FirebaseStorage.instance.ref().child('products/$fileName');
      UploadTask uploadTask = storageReference.putFile(image);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Home Input",
          style: TextStyle(
            fontSize: 28,
          ),
        ),
        backgroundColor: Colors.cyan,
      ),
      body: ListView(
        children: [
          SizedBox(height: 10.0), // Import product name
          Padding(
            padding: EdgeInsets.all(10),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
              controller: _nameController,
            ),
          ),
          SizedBox(height: 10.0), // Import product description
          Padding(
            padding: EdgeInsets.all(10),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Product Description',
                border: OutlineInputBorder(),
              ),
              controller: _descriptionController,
            ),
          ),
          SizedBox(height: 10.0), // Import price
          Padding(
            padding: EdgeInsets.all(10),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
              controller: _priceController,
            ),
          ),
          SizedBox(height: 10.0), // import photos
          Padding(
            padding: EdgeInsets.all(10.0),
            child: InkWell(
              onTap: () => _showImageSourceActionSheet(context),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[300],
                ),
                child: _profileImage != null
                    ? Image.file(
                  _profileImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
                    : Center(
                  child: Text(
                    'Add Photo',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20.0), // Spacer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _save,
                child: Text('Save'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(150, 50), // Set a fixed width for the button
                ),
              ),
              SizedBox(width: 15.0),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductsPage()),
                    );
                  },
                  child: Text('View Products'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
