import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

class ImportExcelPage extends StatefulWidget {
  const ImportExcelPage({Key? key}) : super(key: key);

  @override
  State<ImportExcelPage> createState() => _ImportExcelPageState();
}

class _ImportExcelPageState extends State<ImportExcelPage> {
  String? _fileName;
  String? _filePath;
  bool _uploading = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _fileName = result.files.single.name;
        _filePath = result.files.single.path;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_filePath == null) return;
    setState(() {
      _uploading = true;
    });
    try {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(_filePath!, filename: _fileName),
      });
      var response = await Dio().post(
        "你的上传接口地址", // TODO: 替换为你的接口
        data: formData,
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
          },
        ),
      );
      setState(() {
        _uploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("上传成功:  ${response.data}")),
      );
    } catch (e) {
      setState(() {
        _uploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("上传失败: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入EXCEL表')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('选择Excel文件'),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 16),
              Text('已选择文件: $_fileName'),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (_filePath != null && !_uploading) ? _uploadFile : null,
              child: _uploading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('上传文件'),
            ),
          ],
        ),
      ),
    );
  }
} 