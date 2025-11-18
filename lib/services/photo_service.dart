import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
        if (kIsWeb) {
          // No web, retorna um File temporário usando o path do XFile
          // O path no web é uma string que pode ser usada como identificador
          return File(image.path);
        }
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
        if (kIsWeb) {
          // No web, retorna um File temporário
          return File(image.path);
        }
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Erro ao tirar foto: $e');
      return null;
    }
  }
  
  // Converter XFile para base64 (útil para web)
  Future<String?> imageToBase64(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      final mimeType = image.mimeType ?? 'image/jpeg';
      return 'data:$mimeType;base64,$base64';
    } catch (e) {
      print('Erro ao converter imagem para base64: $e');
      return null;
    }
  }

  // Mostrar dialog para escolher fonte da foto
  // Retorna XFile para funcionar no web
  Future<XFile?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecionar Foto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!kIsWeb) // Câmera não funciona bem no web
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Tirar Foto'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final xfile = await _picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 80,
                    );
                    if (context.mounted && xfile != null) {
                      Navigator.of(context).pop(xfile);
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(kIsWeb ? 'Escolher Arquivo' : 'Escolher da Galeria'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final xfile = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 80,
                  );
                  if (context.mounted && xfile != null) {
                    Navigator.of(context).pop(xfile);
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
  
  // Converter XFile para base64 (funciona no web e mobile)
  Future<String?> convertXFileToBase64(XFile? xfile) async {
    if (xfile == null) return null;
    try {
      final bytes = await xfile.readAsBytes();
      final base64 = base64Encode(bytes);
      final mimeType = xfile.mimeType ?? 'image/jpeg';
      return 'data:$mimeType;base64,$base64';
    } catch (e) {
      print('Erro ao converter imagem para base64: $e');
      return null;
    }
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
              size: radius * 0.8,
              color: Colors.grey[600],
            ),
          );
        }
      } else {
        // Arquivo local
        try {
          photoWidget = CircleAvatar(
            radius: radius,
            backgroundImage: FileImage(File(photoUrl)),
          );
          print('Exibindo foto local: $photoUrl');
        } catch (e) {
          print('Erro ao exibir foto local: $e');
          photoWidget = CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[300],
            child: Icon(
              Icons.person,
              size: radius * 0.8,
              color: Colors.grey[600],
            ),
          );
        }
      }
    } else {
      // Se não tem foto, mostrar ícone padrão
      photoWidget = CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Icon(
          Icons.person,
          size: radius * 0.8,
          color: Colors.grey[600],
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            photoWidget,
            if (showEditIcon)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
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

