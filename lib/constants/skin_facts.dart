
class SkinFacts {
  static const List<String> facts = [
    'Your skin is your body\'s largest organ, covering about 20 square feet!',
    'The scalp has approximately 100,000 hair follicles on average.',
    'Skin renews itself every 28 days through a process called keratinization.',
    'Melanin gives skin its color and protects against harmful UV rays.',
    'The thickest skin is on your feet (1.4mm), while the thinnest is on your eyelids (0.2mm).',
    'Hair grows about 6 inches per year on average.',
    'Your skin contains about 11 miles of blood vessels.',
    'Sweat itself is odorless - body odor comes from bacteria breaking down sweat.',
    'You lose about 30,000 to 40,000 dead skin cells every minute.',
    'The scalp produces an oil called sebum that keeps hair moisturized and healthy.',
    'Skin thickness varies from 0.5mm on your eyelids to 4mm or more on your palms and soles.',
    'Fingernails grow faster than toenails - about 3x faster!',
    'Your skin makes up about 15% of your body weight.',
    'Collagen makes up 75% of your skin and is what prevents wrinkles.',
    'The skin has over 1,000 species of bacteria living on it - most are beneficial!',
    'It takes about 6 months for a fingernail to grow from base to tip.',
    'Skin cells make up about 10% of household dust.',
    'The scalp has a higher concentration of oil glands than any other part of the body.',
    'Vitamin D is synthesized in the skin when exposed to sunlight.',
    'Your skin pH is slightly acidic (around 5.5), which helps protect against harmful bacteria.',
  ];

  static String getRandomFact() {
    final index = DateTime.now().millisecondsSinceEpoch % facts.length;
    return facts[index];
  }
}