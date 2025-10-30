import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class PhotoService {
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();

  final ImagePicker _picker = ImagePicker();

  // Selecionar foto da galeria
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Erro ao selecionar imagem da galeria: $e');
      return null;
    }
  }

  // Tirar foto com a câmera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Erro ao tirar foto: $e');
      return null;
    }
  }

  // Mostrar dialog para escolher fonte da foto
  Future<File?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecionar Foto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar Foto'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await pickImageFromCamera();
                  if (context.mounted) {
                    Navigator.of(context).pop(file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da Galeria'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await pickImageFromGallery();
                  if (context.mounted) {
                    Navigator.of(context).pop(file);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // Widget para exibir foto de perfil
  Widget buildProfilePhoto({
    required String? photoUrl,
    required double radius,
    VoidCallback? onTap,
    bool showEditIcon = true,
  }) {
    Widget photoWidget;
    
    if (photoUrl != null && photoUrl.isNotEmpty) {
      // Se tem foto, mostrar a foto
      if (photoUrl.startsWith('http')) {
        // URL de rede
        photoWidget = CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(photoUrl),
        );
      } else if (photoUrl.startsWith('data:image/')) {
        try {
          final base64Data = photoUrl.split(',').last;
          final bytes = UriData.parse(photoUrl).contentAsBytes();
          photoWidget = CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (_) {
          photoWidget = CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[300],
            child: Icon(
              Icons.person,
              size: radius,
              color: Colors.grey[600],
            ),
          );
        }
      } else {
        // Arquivo local
        photoWidget = CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(File(photoUrl)),
        );
      }
    } else {
      // Se não tem foto, mostrar ícone padrão
      photoWidget = CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Icon(
          Icons.person,
          size: radius,
          color: Colors.grey[600],
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            photoWidget,
            if (showEditIcon)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return photoWidget;
  }
}

