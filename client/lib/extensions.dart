import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';

extension MusicContext on BuildContext {
  MusicProvider get music => read<MusicProvider>();
}
