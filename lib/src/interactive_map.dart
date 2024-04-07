import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:interactive_country_map/src/interactive_map_theme.dart';
import 'package:interactive_country_map/src/map_entity.dart';
import 'package:interactive_country_map/src/map_painter.dart';
import 'package:interactive_country_map/src/svg/svg_parser.dart';

class InteractiveMap extends StatefulWidget {
  const InteractiveMap({
    super.key,
    required this.onCountrySelected,
    required this.map,
    this.theme = const InteractiveMapTheme(),
    this.controller,
    this.loadingWidget,
    this.minZoom = 0.5,
    this.maxZoom = 12,
  }) : assert(minZoom > 0);

  final void Function(String code) onCountrySelected;
  final MapEntity map;
  final InteractiveMapTheme theme;
  final InteractiveMapController? controller;

  // Widget we display during the loading of the map
  final Widget? loadingWidget;

  // Minimum value of a zoom. Must be greater than 0
  final double minZoom;

  // Maximum zoom value
  final double maxZoom;

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  String? svgData;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, loadMap);
  }

  @override
  void didUpdateWidget(InteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.map.name != widget.map.name) {
      loadMap();
    }
  }

  Future<void> loadMap() async {
    final tmp = await DefaultAssetBundle.of(context).loadString(
        "packages/interactive_country_map/res/maps/${widget.map.filename}.svg");

    setState(() {
      svgData = tmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (svgData != null) {
      return Center(
        child: GeographicMap(
          svgData: svgData!,
          theme: widget.theme,
          onCountrySelected: widget.onCountrySelected,
          minZoom: widget.minZoom,
          maxZoom: widget.maxZoom,
        ),
      );
    } else {
      return widget.loadingWidget ?? const SizedBox.shrink();
    }
  }
}

class GeographicMap extends StatefulWidget {
  const GeographicMap({
    super.key,
    required this.svgData,
    required this.theme,
    required this.onCountrySelected,
    required this.minZoom,
    required this.maxZoom,
  });

  final String svgData;
  final InteractiveMapTheme theme;
  final void Function(String code) onCountrySelected;

  final double minZoom;

  final double maxZoom;

  @override
  State<GeographicMap> createState() => _GeographicMapState();
}

class _GeographicMapState extends State<GeographicMap> {
  List<CountryPath> countries = [];
  Offset? cursorPosition;
  Offset offset = Offset.zero;

  double _scale = 1.0;
  double _draggingScale = 1.0;

  @override
  void initState() {
    super.initState();

    _parseSvg();
  }

  @override
  void didUpdateWidget(GeographicMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.svgData != widget.svgData) {
      _parseSvg();
    }
  }

  Future<void> _parseSvg() async {
    final newPaths = await SvgParser().parse(widget.svgData);

    setState(() {
      countries = newPaths;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        onTapDown: (details) {
          setState(() {
            cursorPosition = details.localPosition;
          });

          final selectedCountry = countries.firstWhereOrNull((element) =>
              element.path.toPath(1, offset).contains(details.localPosition));

          if (selectedCountry != null) {
            widget.onCountrySelected(selectedCountry.countryCode);
          }
        },
        onScaleStart: (details) {
          _draggingScale = _scale;
        },
        onScaleUpdate: (details) {
          setState(() {
            offset = offset + details.focalPointDelta;
            cursorPosition = details.localFocalPoint;

            final possibleNewScale = _draggingScale * details.scale;
            if (widget.minZoom <= possibleNewScale &&
                possibleNewScale <= widget.maxZoom) {
              _scale = _draggingScale * details.scale;
            }
          });
        },
        child: CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: MapPainter(
            countries: countries,
            cursorPosition: cursorPosition,
            offset: offset,
            theme: widget.theme,
            scale: _scale,
          ),
        ),
      ),
    );
  }
}

class InteractiveMapController {
  InteractiveMapController();
}
