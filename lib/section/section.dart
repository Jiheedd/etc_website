enum Section {
  intro,
  videos,
  // video,
  gallery,
  joinUs,
}
extension SectionX on Section {
  String get trKey {
    switch (this) {
      case Section.intro:
        return 'section_intro';
      case Section.videos:
        return 'section_videos';
      case Section.gallery:
        return 'section_gallery';
      case Section.joinUs:
        return 'section_join_us';
    }
  }
}
