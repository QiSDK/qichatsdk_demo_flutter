
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class MyPdfViewer extends StatefulWidget {
  final String fileUrl;

  const MyPdfViewer({Key? key, required this.fileUrl})
      : super(key: key);

  @override
  State<MyPdfViewer> createState() => _MyPdfViewerState();
}

class _MyPdfViewerState extends State<MyPdfViewer> {

  final controller = PdfViewerController();
  // create a PdfTextSearcher and add a listener to update the GUI on search result changes
  late final textSearcher = PdfTextSearcher(controller)..addListener(_update);

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
          params: PdfViewerParams(
            maxScale: 8,
              enableTextSelection: true,
            // add pageTextMatchPaintCallback that paints search hit highlights
            pagePaintCallbacks: [
              textSearcher.pageTextMatchPaintCallback
            ],
            viewerOverlayBuilder: (context, size, handleLinkTap) => [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                // Your code here:
                onDoubleTap: () {
                  controller.zoomUp(loop: true);
                },
                // If you use GestureDetector on viewerOverlayBuilder, it breaks link-tap handling
                // and you should manually handle it using onTapUp callback
                onTapUp: (details) {
                  handleLinkTap(details.localPosition);
                },
                // Make the GestureDetector covers all the viewer widget's area
                // but also make the event go through to the viewer.
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