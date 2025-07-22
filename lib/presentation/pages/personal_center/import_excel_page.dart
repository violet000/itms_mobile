import 'dart:io' as io show File;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:itms_mobile/core/constants/constant.dart';
import 'package:itms_mobile/data/datasources/api/9087/service_9087.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:itms_mobile/presentation/widgets/common/message_toast.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

class ImportExcelPage extends StatefulWidget {
  const ImportExcelPage({Key? key}) : super(key: key);

  @override
  State<ImportExcelPage> createState() => _ImportExcelPageState();
}

class _ImportExcelPageState extends State<ImportExcelPage> {
  String? _fileName;
  String? _filePath;
  Uint8List? _fileBytes;
  bool _uploading = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
      withData: kIsWeb,
    );
    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        if (kIsWeb) {
          _filePath = null;
          _fileBytes = result.files.single.bytes;
        } else {
          _filePath = result.files.single.path;
          _fileBytes = null;
        }
      });
    }
  }

  /// 上传文件
  Future<void> _uploadFile() async {
    if ((!kIsWeb && _filePath == null) || (kIsWeb && _fileBytes == null))
      return;
    setState(() {
      _uploading = true;
    });
    try {
      final service = await Service9087.create();
      MultipartFile multipartFile;
      if (kIsWeb) {
        if (_fileBytes == null || _fileName == null) {
          context.showErrorMessage('请选择文件');
          setState(() => _uploading = false);
          return;
        }
        multipartFile =
            MultipartFile.fromBytes(_fileBytes!, filename: _fileName);
      } else {
        multipartFile =
            await MultipartFile.fromFile(_filePath!, filename: _fileName);
      }
      FormData formData = FormData.fromMap(<String, dynamic>{
        'file': multipartFile,
      });
      final Map<String, dynamic> response =
          await service.addLocationByFormData(formData);
      setState(() {
        _uploading = false;
      });
      if (response['retCode'] == HTTPCode.success.code) {
        context.showSuccessMessage('上传成功: ${response['retMsg'] ?? ''}');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {'selectedTab': 2},
        );
      } else {
        context.showErrorMessage('上传失败: ${response['retMsg'] ?? '未知错误'}');
      }
    } catch (e) {
      setState(() {
        _uploading = false;
      });
      context.showErrorMessage('上传失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '地标文件导入',
      showBackButton: true,
      onBackPressed: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {'selectedTab': 2},
        );
      },
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          // decoration: BoxDecoration(
          //   color: Colors.white.withOpacity(0.95),
          //   borderRadius: BorderRadius.circular(16),
          //   boxShadow: [
          //     BoxShadow(
          //       color: Colors.black.withOpacity(0.06),
          //       blurRadius: 16,
          //       offset: const Offset(0, 8),
          //     ),
          //   ],
          // ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '请选择要导入的Excel文件',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3C5078)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                '注意: 平面库, 关联位置Z值可设置1或不填, 其余不可为空',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 229, 3, 3)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file, color: Color(0xFF1976D2)),
                label: const Text('选择Excel文件', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF1976D2)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (_fileName != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE3E6ED)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file,
                          color: Color(0xFF1976D2)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fileName!,
                          style: const TextStyle(
                              fontSize: 15, color: Color(0xFF3C5078)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 20, color: Colors.grey),
                        onPressed: _uploading
                            ? null
                            : () {
                                setState(() {
                                  _fileName = null;
                                  _filePath = null;
                                  _fileBytes = null;
                                });
                              },
                        tooltip: '移除文件',
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (((!kIsWeb && _filePath != null) ||
                              (kIsWeb && _fileBytes != null)) &&
                          !_uploading)
                      ? _uploadFile
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _uploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('上传文件'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
