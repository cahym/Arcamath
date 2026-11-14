import 'package:flutter/material.dart';

const kAppName = 'Arcamath';


const kTeamMembers = ['Camila Martins', 'Eline Vieira'];

const kGoogleClientId = '475631228171-vnls3f2k31ejmchocantd11v0oqfr75c.apps.googleusercontent.com';

/// Fontes oferecidas nas configuracoes (todas via google_fonts).
/// "Garamond" = EB Garamond; "Helvetica" nao existe no Google Fonts, Arimo e o equivalente.
const kFontFamilies = ['Press Start 2P', 'Silkscreen', 'VT323', 'Orbitron', 'Roboto', 'EB Garamond', 'Arimo'];

/// Cores semente neon oferecidas ao usuario (alem do seletor livre de matiz).
const kSeedPresets = <Color>[
  Color(0xFF6B4EFF), // violeta (padrao, como a referencia roxa)
  Color(0xFF2B3BE8), // azul noite (referencia "PRESS START")
  Color(0xFF00ACC1), // turquesa
  Color(0xFFE91E63), // rosa
  Color(0xFF43A047), // verde
  Color(0xFFFB8C00), // laranja
];

const kLastRouteKey = 'last_route';
const kLevelKey = 'level';
const kValidRoutes = ['/game', '/ranking', '/settings'];
