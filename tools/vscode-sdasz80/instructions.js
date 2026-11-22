// Z80 instructions: [forms, flags, T-states, description]
// Flags, in the order S Z H P/V N C: * changed, - unchanged, 0 / 1 forced, V overflow, P parity, ? undefined
// Operands: r = a b c d e h l, n / nn = constant, (nn) = memory at an address, rr = bc de hl sp,
// qq = bc de hl af, x = ix iy, (x+d) = (ix+d) (iy+d), cc = condition, b = bit number

const NONE = '------';

// 8-bit operations on A: r, n, (hl), (ix+d), with or without the leading "a,"
const alu = (name, flags, text) => [
  [[`${name} a,r`], flags, '4', text],
  [[`${name} a,n`, `${name} a,(hl)`], flags, '7', text],
  [[`${name} a,(x+d)`], flags, '19', text],
];
const shift = (name, text, flags = '**0P0*') => [
  [[`${name} r`], flags, '8', text],
  [[`${name} (hl)`], flags, '15', text],
  [[`${name} (x+d)`], flags, '23', text],
];
const bits = (name, text) => [
  [[`${name} b,r`], NONE, '8', text],
  [[`${name} b,(hl)`], NONE, '15', text],
  [[`${name} b,(x+d)`], NONE, '23', text],
];

const COPY = 'Copie la source (à droite) dans la destination (à gauche).';

module.exports = {
  ld: [
    [['ld r,r'], NONE, '4', COPY],
    [['ld r,n', 'ld r,(hl)', 'ld (hl),r', 'ld a,(bc)', 'ld a,(de)', 'ld (bc),a', 'ld (de),a'], NONE, '7', COPY],
    [['ld (hl),n'], NONE, '10', COPY],
    [['ld r,(x+d)', 'ld (x+d),r', 'ld (x+d),n'], NONE, '19', COPY],
    [['ld a,(nn)', 'ld (nn),a'], NONE, '13', COPY],
    [['ld rr,nn'], NONE, '10', COPY],
    [['ld x,nn'], NONE, '14', COPY],
    [['ld hl,(nn)', 'ld (nn),hl'], NONE, '16', COPY + ' L est à l\'adresse nn, H à nn + 1.'],
    [['ld rr,(nn)', 'ld (nn),rr', 'ld x,(nn)', 'ld (nn),x'], NONE, '20', COPY + ' Octet de poids faible en premier.'],
    [['ld sp,hl'], NONE, '6', COPY],
    [['ld sp,x'], NONE, '10', COPY],
    [['ld a,i', 'ld a,r!'], '**0*0-', '9', COPY + ' P/V = 1 si les interruptions sont autorisées.'],
    [['ld i,a', 'ld r!,a'], NONE, '9', COPY],
  ],
  push: [
    [['push qq'], NONE, '11', 'Empile un registre 16 bits : SP = SP - 2. Le registre ne change pas.'],
    [['push x'], NONE, '15', 'Empile un registre 16 bits : SP = SP - 2. Le registre ne change pas.'],
  ],
  pop: [
    [['pop af'], '******', '10', 'Dépile A et les flags : SP = SP + 2. Tous les flags sont remplacés.'],
    [['pop qq'], NONE, '10', 'Dépile vers un registre 16 bits : SP = SP + 2.'],
    [['pop x'], NONE, '14', 'Dépile vers un registre 16 bits : SP = SP + 2.'],
  ],
  ex: [
    [['ex de,hl'], NONE, '4', 'Échange DE et HL.'],
    [["ex af,af'"], '******', '4', "Échange AF et AF' : A et les flags sont remplacés."],
    [['ex (sp),hl'], NONE, '19', 'Échange le registre et le mot en haut de la pile. SP ne change pas.'],
    [['ex (sp),x'], NONE, '23', 'Échange le registre et le mot en haut de la pile. SP ne change pas.'],
  ],
  exx: [[['exx'], NONE, '4', "Échange BC, DE, HL avec BC', DE', HL'."]],
  ldi: [[['ldi'], '--0*0-', '16', '(DE) = (HL), puis HL + 1, DE + 1, BC - 1. P/V = 0 quand BC arrive à 0.']],
  ldd: [[['ldd'], '--0*0-', '16', '(DE) = (HL), puis HL - 1, DE - 1, BC - 1. P/V = 0 quand BC arrive à 0.']],
  ldir: [[['ldir'], '--000-', '21 par octet, 16 pour le dernier', 'Copie BC octets de (HL) vers (DE), en avançant. À la fin : BC = 0, HL et DE juste après les blocs.']],
  lddr: [[['lddr'], '--000-', '21 par octet, 16 pour le dernier', 'Copie BC octets de (HL) vers (DE), en reculant. À la fin : BC = 0, HL et DE juste avant les blocs.']],
  cpi: [[['cpi'], '****1-', '16', 'Compare A à (HL), puis HL + 1, BC - 1. Z = 1 si égal, P/V = 0 quand BC arrive à 0.']],
  cpd: [[['cpd'], '****1-', '16', 'Compare A à (HL), puis HL - 1, BC - 1. Z = 1 si égal, P/V = 0 quand BC arrive à 0.']],
  cpir: [[['cpir'], '****1-', '21 par octet, 16 pour le dernier', 'Cherche A à partir de (HL), BC octets au plus, en avançant. Z = 1 si trouvé (HL juste après).']],
  cpdr: [[['cpdr'], '****1-', '21 par octet, 16 pour le dernier', 'Cherche A à partir de (HL), BC octets au plus, en reculant. Z = 1 si trouvé (HL juste avant).']],

  add: [
    ...alu('add', '***V0*', 'A = A + s. C = 1 si le résultat dépasse 255.'),
    [['add hl,rr'], '--*-0*', '11', 'HL = HL + rr. C = 1 si le résultat dépasse 65535. Z ne change pas !'],
    [['add x,bc', 'add x,de', 'add x,sp', 'add ix,ix', 'add iy,iy'], '--*-0*', '15', 'Addition 16 bits. C = 1 si le résultat dépasse 65535. Z ne change pas !'],
  ],
  adc: [
    ...alu('adc', '***V0*', 'A = A + s + C. C = 1 si le résultat dépasse 255.'),
    [['adc hl,rr'], '***V0*', '15', 'HL = HL + rr + C. Mettre C à 0 avant (or a, a) pour une addition simple.'],
  ],
  sub: alu('sub', '***V1*', 'A = A - s. C = 1 si A < s (non signé), Z = 1 si A = s.'),
  sbc: [
    ...alu('sbc', '***V1*', 'A = A - s - C. C = 1 si le résultat passe sous 0.'),
    [['sbc hl,rr'], '***V1*', '15', 'HL = HL - rr - C. Mettre C à 0 avant (or a, a) pour une soustraction simple. Ensuite : C = 1 si HL < rr, Z = 1 si HL = rr.'],
  ],
  cp: alu('cp', '***V1*', 'Compare A à s : calcule A - s sans changer A. Z = 1 si A = s, C = 1 si A < s, C = 0 si A >= s (non signé).'),
  and: alu('and', '**1P00', 'A = A ET s, bit à bit. Garde les bits à 1 dans s, met les autres à 0. C = 0.'),
  or: alu('or', '**0P00', 'A = A OU s, bit à bit. or a, a ne change pas A : met C à 0, et Z = 1 si A = 0.'),
  xor: alu('xor', '**0P00', 'A = A OU exclusif s, bit à bit. xor a, a met A à 0. C = 0.'),
  inc: [
    [['inc r'], '***V0-', '4', 'Ajoute 1. Z = 1 si le résultat est 0. C ne change pas.'],
    [['inc (hl)'], '***V0-', '11', 'Ajoute 1 à l\'octet en mémoire. Z = 1 si le résultat est 0. C ne change pas.'],
    [['inc (x+d)'], '***V0-', '23', 'Ajoute 1 à l\'octet en mémoire. Z = 1 si le résultat est 0. C ne change pas.'],
    [['inc rr'], NONE, '6', 'Ajoute 1 à un registre 16 bits. Aucun flag ne change, même Z !'],
    [['inc x'], NONE, '10', 'Ajoute 1 à un registre 16 bits. Aucun flag ne change, même Z !'],
  ],
  dec: [
    [['dec r'], '***V1-', '4', 'Retire 1. Z = 1 si le résultat est 0. C ne change pas.'],
    [['dec (hl)'], '***V1-', '11', 'Retire 1 à l\'octet en mémoire. Z = 1 si le résultat est 0. C ne change pas.'],
    [['dec (x+d)'], '***V1-', '23', 'Retire 1 à l\'octet en mémoire. Z = 1 si le résultat est 0. C ne change pas.'],
    [['dec rr'], NONE, '6', 'Retire 1 à un registre 16 bits. Aucun flag ne change, même Z ! Pour tester 0 : ld a, b / or a, c.'],
    [['dec x'], NONE, '10', 'Retire 1 à un registre 16 bits. Aucun flag ne change, même Z !'],
  ],
  daa: [[['daa'], '***P-*', '4', 'Corrige A après une addition ou une soustraction de nombres BCD.']],
  cpl: [[['cpl'], '--1-1-', '4', 'Inverse tous les bits de A.']],
  neg: [[['neg'], '***V1*', '8', 'A = 0 - A.']],
  ccf: [[['ccf'], '--*-0*', '4', 'Inverse C (H prend l\'ancien C).']],
  scf: [[['scf'], '--0-01', '4', 'Met C à 1. Pour le mettre à 0 : or a, a.']],

  rlca: [[['rlca'], '--0-0*', '4', 'Tourne A d\'un bit à gauche : le bit 7 va dans C et dans le bit 0.']],
  rla: [[['rla'], '--0-0*', '4', 'Tourne A d\'un bit à gauche à travers C : bit 7 vers C, ancien C vers le bit 0.']],
  rrca: [[['rrca'], '--0-0*', '4', 'Tourne A d\'un bit à droite : le bit 0 va dans C et dans le bit 7.']],
  rra: [[['rra'], '--0-0*', '4', 'Tourne A d\'un bit à droite à travers C : bit 0 vers C, ancien C vers le bit 7.']],
  rlc: shift('rlc', 'Tourne d\'un bit à gauche : le bit 7 va dans C et dans le bit 0.'),
  rl: shift('rl', 'Tourne d\'un bit à gauche à travers C : bit 7 vers C, ancien C vers le bit 0.'),
  rrc: shift('rrc', 'Tourne d\'un bit à droite : le bit 0 va dans C et dans le bit 7.'),
  rr: shift('rr', 'Tourne d\'un bit à droite à travers C : bit 0 vers C, ancien C vers le bit 7. Après srl d : rr e continue un décalage 16 bits.'),
  sla: shift('sla', 'Décale d\'un bit à gauche (multiplie par 2) : bit 7 vers C, 0 dans le bit 0.'),
  sra: shift('sra', 'Décale d\'un bit à droite (divise par 2, signé) : bit 0 vers C, le bit 7 reste.'),
  srl: shift('srl', 'Décale d\'un bit à droite (divise par 2, non signé) : bit 0 vers C, 0 dans le bit 7.', '0*0P0*'),
  rld: [[['rld'], '**0P0-', '18', 'Fait tourner 3 demi-octets à gauche : bits 0-3 de A, puis les deux moitiés de (HL).']],
  rrd: [[['rrd'], '**0P0-', '18', 'Fait tourner 3 demi-octets à droite : bits 0-3 de A, puis les deux moitiés de (HL).']],
  bit: [
    [['bit b,r'], '?*1?0-', '8', 'Teste un bit : Z = 1 si le bit est à 0.'],
    [['bit b,(hl)'], '?*1?0-', '12', 'Teste un bit : Z = 1 si le bit est à 0.'],
    [['bit b,(x+d)'], '?*1?0-', '20', 'Teste un bit : Z = 1 si le bit est à 0.'],
  ],
  set: bits('set', 'Met un bit à 1.'),
  res: bits('res', 'Met un bit à 0.'),

  jp: [
    [['jp cc,nn', 'jp nn'], NONE, '10', 'Saute à l\'adresse, si la condition est vraie quand il y en a une.'],
    [['jp (hl)'], NONE, '4', 'Saute à l\'adresse contenue dans HL (pas à celle lue en mémoire).'],
    [['jp (x)'], NONE, '8', 'Saute à l\'adresse contenue dans le registre (pas à celle lue en mémoire).'],
  ],
  jr: [
    [['jr jc,nn'], NONE, '12 si saut, sinon 7', 'Saut court (-126 à +129 octets) si la condition est vraie. Seulement z, nz, c, nc.'],
    [['jr nn'], NONE, '12', 'Saut court (-126 à +129 octets).'],
  ],
  djnz: [[['djnz nn'], NONE, '13 si saut, sinon 8', 'B = B - 1, puis saut court si B n\'est pas 0. Ne change aucun flag.']],
  call: [
    [['call cc,nn'], NONE, '17 si appel, sinon 10', 'Appelle une routine si la condition est vraie : empile l\'adresse de retour et saute.'],
    [['call nn'], NONE, '17', 'Appelle une routine : empile l\'adresse de retour et saute.'],
  ],
  ret: [
    [['ret cc'], NONE, '11 si retour, sinon 5', 'Revient à l\'appelant si la condition est vraie : dépile l\'adresse de retour.'],
    [['ret'], NONE, '10', 'Revient à l\'appelant : dépile l\'adresse de retour.'],
  ],
  reti: [[['reti'], NONE, '14', 'Fin d\'une routine d\'interruption.']],
  retn: [[['retn'], NONE, '14', 'Fin d\'une routine NMI : rétablit l\'état des interruptions.']],
  rst: [[['rst n'], NONE, '11', 'Appel court à une adresse fixe : 0x00, 0x08, 0x10 ... 0x38.']],

  in: [
    [['in a,(nn)'], NONE, '11', 'Lit un port dans A. Aucun flag ne change.'],
    [['in r,(c)'], '**0P0-', '12', 'Lit le port dont le numéro est dans C. Z = 1 si l\'octet lu est 0.'],
  ],
  out: [
    [['out (nn),a'], NONE, '11', 'Écrit A sur un port.'],
    [['out (c),r'], NONE, '12', 'Écrit un registre sur le port dont le numéro est dans C.'],
  ],
  ini: [[['ini'], '?*????', '16', '(HL) = port C, puis HL + 1, B - 1. Z = 1 quand B arrive à 0.']],
  ind: [[['ind'], '?*????', '16', '(HL) = port C, puis HL - 1, B - 1. Z = 1 quand B arrive à 0.']],
  inir: [[['inir'], '?1????', '21 par octet, 16 pour le dernier', 'Lit B octets du port C vers (HL), en avançant (B = 0 : 256 octets).']],
  indr: [[['indr'], '?1????', '21 par octet, 16 pour le dernier', 'Lit B octets du port C vers (HL), en reculant (B = 0 : 256 octets).']],
  outi: [[['outi'], '?*????', '16', 'Port C = (HL), puis HL + 1, B - 1. Z = 1 quand B arrive à 0.']],
  outd: [[['outd'], '?*????', '16', 'Port C = (HL), puis HL - 1, B - 1. Z = 1 quand B arrive à 0.']],
  otir: [[['otir'], '?1????', '21 par octet, 16 pour le dernier', 'Écrit B octets de (HL) vers le port C, en avançant (B = 0 : 256 octets).']],
  otdr: [[['otdr'], '?1????', '21 par octet, 16 pour le dernier', 'Écrit B octets de (HL) vers le port C, en reculant (B = 0 : 256 octets).']],

  nop: [[['nop'], NONE, '4', 'Ne fait rien.']],
  halt: [[['halt'], NONE, '4', 'Attend une interruption.']],
  di: [[['di'], NONE, '4', 'Interdit les interruptions (pas la NMI).']],
  ei: [[['ei'], NONE, '4', 'Autorise les interruptions, après l\'instruction suivante.']],
  im: [[['im n'], NONE, '8', 'Choisit le mode d\'interruption : 0, 1 ou 2.']],
};
