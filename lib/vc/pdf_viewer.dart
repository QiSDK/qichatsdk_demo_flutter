import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class MyPdfViewer extends StatefulWidget {
  final String fileUrl;

  const MyPdfViewer({Key? key, required this.fileUrl}) : super(key: key);

  @override
  State<MyPdfViewer> createState() => _MyPdfViewerState();
}

class _MyPdfViewerState extends State<MyPdfViewer> {
  final controller = PdfViewerController();
  // create a PdfTextSearcher and add a listener to update the GUI on search result changes
  late final textSearcher = PdfTextSearcher(controller)..addListener(_update);
  var isZoomUp = false;
  var tapCount = 0;

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // dispose the PdfTextSearcher
    textSearcher.removeListener(_update);
    textSearcher.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            '客服',
            style: TextStyle(fontSize: 18),
          ),
        ),
        body: PdfViewer.uri(
          Uri.parse(widget.fileUrl),
          controller: controller,
          params: PdfViewerParams(
            maxScale: 8,
            enableTextSelection: true,
            panEnabled: true,
            scaleEnabled: true,
            // add pageTextMatchPaintCallback that paints search hit highlights
            pagePaintCallbacks: [textSearcher.pageTextMatchPaintCallback],
            viewerOverlayBuilder: (context, size, handleLinkTap) => [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: () {
                  if (tapCount == 4){
                    tapCount = 0;
                  }
                  if (tapCount < 2){
                    controller.zoomUp();
                  }else{
                    controller.zoomDown();
                  }
                  tapCount += 1;
                },
                onTapUp: (details) {
                  handleLinkTap(details.localPosition);
                },
                child: IgnorePointer(
                  child:
                  SizedBox(width: size.width, height: size.height),
                ),
              ),
            ],
          ),
          passwordProvider: () => 'test',
        ));
  }
}
