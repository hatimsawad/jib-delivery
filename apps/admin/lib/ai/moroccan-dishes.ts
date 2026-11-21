export type MoroccanDishProfile = {
  id: string;
  aliases: string[];
  visualBrief: string;
  exclusions: string;
};

const profiles: MoroccanDishProfile[] = [
  {
    id: "moroccan-french-tacos",
    aliases: ["tacos", "taco", "tacos poulet", "tacos marocain", "tacos français", "طاكوس", "تاكوس", "طاكوس الدجاج", "تاكوس الدجاج", "طاكوس مغربي", "تاكوس مغربي"],
    visualBrief: "MOROCCAN/FRENCH TACOS SANDWICH, not Mexican tacos: one large wheat-flour tortilla folded into a compact sealed rectangular or square parcel, pressed flat in a contact grill and toasted golden with subtle grill marks. It is a closed grilled sandwich, optionally cut once diagonally to reveal a dense cross-section. Keep the specified chicken or other named filling, fries and creamy cheese sauce inside the wrap; use only ingredients stated in the product description.",
    exclusions: "Never depict Mexican tacos, U-shaped shells, open upright shells, small corn tortillas, taco boats, nachos, multiple little tacos, or loose filling scattered on the plate.",
  },
  {
    id: "moroccan-tajine",
    aliases: ["tajine", "tagine", "tajin", "طاجين", "الطاجين", "طاجين مغربي", "طاجين الدجاج", "طاجين اللحم", "طاجين بالخضر"],
    visualBrief: "AUTHENTIC MOROCCAN TAJINE: the food is the hero, served inside a traditional shallow round glazed earthenware Moroccan tagine base, with its distinctive conical clay lid either lifted and placed behind the base or slightly ajar so the actual stew is clearly visible. Show a moist, slowly braised Moroccan stew with natural sauce and tender pieces. Follow the named protein and ingredients exactly; if unspecified, keep the stew simple and do not invent a specific meat, fruit, olives, eggs or garnish. The tagine vessel must be visible and unmistakable.",
    exclusions: "Never show a living room, kitchen interior, cook/person, chef portrait, empty serving dish, generic casserole, metal pot, couscous mound, or food styling unrelated to the named tagine.",
  },
  {
    id: "moroccan-couscous",
    aliases: ["couscous", "كسكس", "الكسكس", "كسكس مغربي", "كسكس بالخضر", "كسكس بالدجاج", "كسكس باللحم"],
    visualBrief: "AUTHENTIC MOROCCAN COUSCOUS served as fine steamed couscous grains in a wide traditional serving platter, topped and surrounded by the exact named vegetables and protein, with broth/moisture naturally visible. Follow the description; do not invent meat or vegetables.",
    exclusions: "No pasta, rice, paella, risotto, quinoa, or generic grain bowl.",
  },
  {
    id: "moroccan-pastilla",
    aliases: ["pastilla", "bastilla", "bastila", "بسطيلة", "بستيلة", "بسطيلة الدجاج", "بسطيلة الحوت"],
    visualBrief: "AUTHENTIC MOROCCAN PASTILLA: a round, delicate, multi-layered warqa pastry pie with crisp thin golden flaky pastry, presented whole or with one clean wedge cut to reveal the correct layered filling. Match the named filling (poultry, seafood, or other) and only use toppings specified.",
    exclusions: "No pizza crust, puff-pastry turnover, pie with thick western crust, or unrelated dessert.",
  },
  {
    id: "moroccan-harira",
    aliases: ["harira", "حريرة", "الحريرة", "حريرة مغربية"],
    visualBrief: "AUTHENTIC MOROCCAN HARIRA: a rich red-orange tomato-based Moroccan soup in a traditional soup bowl, with visible lentils, chickpeas, herbs and fine vermicelli only when consistent with the supplied description. Show soup, not a solid stew.",
    exclusions: "No cream soup, ramen, pho, or chunky western vegetable stew.",
  },
  {
    id: "moroccan-rfissa",
    aliases: ["rfissa", "رفيسة", "الرفيسة"],
    visualBrief: "AUTHENTIC MOROCCAN RFISSA: shredded msemen or trid pastry pieces forming a soft bed, topped with chicken and lentil-rich fenugreek broth, arranged in a traditional Moroccan serving platter. Follow the named ingredients.",
    exclusions: "No couscous, pasta, pizza, or plain roast chicken plate.",
  },
  {
    id: "moroccan-tanjia",
    aliases: ["tanjia", "tangia", "طنجية", "الطنجية", "طنجية مراكشية"],
    visualBrief: "AUTHENTIC MARRAKECH TANJIA: tender slow-cooked meat in its rich reduced sauce, served in or beside the characteristic rounded terracotta tanjia vessel. Use the exact named meat and listed preserved lemon/spices; do not turn it into a tagine.",
    exclusions: "No conical tagine lid, barbecue skewers, steakhouse plating, or unrelated stew.",
  },
  {
    id: "moroccan-msemen",
    aliases: ["msemen", "rghaif", "مسمن", "المسمن", "رغايف", "ملوي", "ملوي مغربي"],
    visualBrief: "AUTHENTIC MOROCCAN MSEMEN/RGHAIF: thin square or round laminated folded griddle flatbread with delicate visible layers, golden toasted spots and a lightly crisp surface. Match sweet or savory serving exactly as described.",
    exclusions: "No pita pocket, naan, tortilla wrap, croissant, or thick American pancake.",
  },
  {
    id: "moroccan-chebakia",
    aliases: ["chebakia", "chbakia", "شباكية", "الشباكية"],
    visualBrief: "AUTHENTIC MOROCCAN CHEBAKIA: intricately folded flower-like sesame dough pastries, deep golden and glossy with honey, sprinkled with sesame seeds, arranged in a small neat pile. Show the characteristic knotted rosette shape.",
    exclusions: "No doughnuts, croissants, baklava triangles, or generic cookies.",
  },
  {
    id: "moroccan-zaalouk",
    aliases: ["zaalouk", "zaaluk", "زعلوك", "الزعلوك"],
    visualBrief: "AUTHENTIC MOROCCAN ZAALOUK: a rustic cooked eggplant and tomato salad/dip, softly mashed but visibly textured, glossy with olive oil and herbs, served in a small traditional Moroccan ceramic dish. Match the supplied ingredient description.",
    exclusions: "No baba ganoush with tahini, hummus, guacamole, or raw salad.",
  },
  {
    id: "moroccan-bissara",
    aliases: ["bissara", "بيصارة", "بصارة", "البيصارة"],
    visualBrief: "AUTHENTIC MOROCCAN BISSARA: thick pale cream-to-green fava bean or split-pea purée soup in a rustic bowl, finished only with the specified olive oil, cumin and paprika. Show its dense silky soup texture.",
    exclusions: "No hummus bowl, mashed potatoes, green guacamole, or thin clear soup.",
  },
  {
    id: "moroccan-briouat",
    aliases: ["briouat", "briouates", "briwat", "بريوات", "بريوة"],
    visualBrief: "AUTHENTIC MOROCCAN BRIOUATS: small crisp golden warqa pastry parcels, triangular or cigar-shaped according to the described variety, with the exact sweet or savory filling. Show delicate crisp pastry layers.",
    exclusions: "No samosas unless explicitly requested, no spring rolls, no dumplings, no croissants.",
  },
  {
    id: "moroccan-maakouda",
    aliases: ["maakouda", "maaqouda", "معقودة", "المعقودة"],
    visualBrief: "AUTHENTIC MOROCCAN MAAKOUDA: round flattened potato fritters, golden and crisp outside with a soft potato interior, served as the actual fritters and matched to the specified sandwich or plate presentation.",
    exclusions: "No hash browns, French fries pile, pancakes, or meat patties.",
  },
  {
    id: "moroccan-seffa",
    aliases: ["seffa", "سفة", "السفة", "سفة مدفونة"],
    visualBrief: "AUTHENTIC MOROCCAN SEFFA: a carefully piled mound of fine steamed vermicelli or couscous (use the exact type in the description), lightly dusted with powdered sugar and cinnamon only when specified, with almonds/raisins only if listed.",
    exclusions: "No spaghetti with tomato sauce, rice pudding, or western pasta salad.",
  },
];

function normalizeDishText(value: string): string {
  return value
    .toLocaleLowerCase()
    .normalize("NFKD")
    .replace(/[\u064B-\u065F\u0670\u0640]/g, "")
    .replace(/[أإآٱ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ة/g, "ه")
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .trim()
    .replace(/\s+/g, " ");
}

export function findMoroccanDishProfile(title: string): MoroccanDishProfile | null {
  const normalizedTitle = normalizeDishText(title);
  if (!normalizedTitle) return null;

  for (const profile of profiles) {
    const matched = profile.aliases.some((alias) => {
      const normalizedAlias = normalizeDishText(alias);
      // Match whole words or phrases only; substring matches can confuse unrelated products.
      return normalizedTitle === normalizedAlias ||
        normalizedTitle.startsWith(`${normalizedAlias} `) ||
        normalizedTitle.endsWith(` ${normalizedAlias}`) ||
        normalizedTitle.includes(` ${normalizedAlias} `);
    });
    if (matched) return profile;
  }
  return null;
}

export function buildMoroccanDishPrompt(title: string): string | null {
  const profile = findMoroccanDishProfile(title);
  if (!profile) return null;
  return [
    "REGIONAL DISH REFERENCE LIBRARY MATCH:",
    `Dish profile: ${profile.id}.`,
    profile.visualBrief,
    profile.exclusions,
    "Photograph only the actual prepared dish as a close-up hero subject. Do not substitute a room, restaurant interior, cook, person, ingredients still being prepared, or a lifestyle scene.",
  ].join(" ");
}
