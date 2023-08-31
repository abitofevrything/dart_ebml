import 'dart:collection';

import 'package:petitparser/petitparser.dart';

import 'schema.dart';

/// A petitparser grammar that can parse EBML Element paths.
class PathGrammar extends GrammarDefinition<Path> {
  /// Create a new [PathGrammar].
  const PathGrammar();

  List<E> _flatten<E>(List<List<E>> lists) =>
      lists.expand((_) => _).toList(growable: false);
  String _join(List<String> list) => list.join();
  Path _elementsToPath(List<PathElement> elements) =>
      Path(UnmodifiableListView(elements));
  GlobalPlaceholder _limitsToGlobalPlaceHolder((int?, int?) limits) =>
      GlobalPlaceholder(minOccurrences: limits.$1, maxOccurrences: limits.$2);

  @override
  Parser<Path> start() => ref0(ebmlFullPath).end();

  /// EBMLFullPath           = EBMLParentPath EBMLElement
  Parser<Path> ebmlFullPath() => [
        ref0(ebmlParentPath),
        ref0(ebmlElement).map((_) => [_]),
      ].toSequenceParser().map(_flatten).map(_elementsToPath);

  /// EBMLParentPath         = PathDelimiter [EBMLParents]
  Parser<List<PathElement>> ebmlParentPath() => (
        ref0(pathDelimiter),
        ref0(ebmlParents).optionalWith(<PathElement>[]),
      ).toSequenceParser().map((value) => value.$2);

  /// EBMLParents            = 0*IntermediatePathAtom EBMLLastParent
  Parser<List<PathElement>> ebmlParents() => [
        ref0(intermediatePathAtom)
            // We need to specify [starGreedy] instead of [star] so our parser does not consume the
            // entire input as [intermediatePathAtom]s, leaving enough input for [ebmlLastParent]
            // and [ebmlElement] to parse ([ebmlLastParent] is next in this sequence parser, and
            // [ebmlElement] is the last element in the input)
            .starGreedy(ref0(ebmlLastParent) & ref0(ebmlElement)),
        ref0(ebmlLastParent).map((_) => [_]),
      ].toSequenceParser().map(_flatten);

  /// IntermediatePathAtom   = EBMLPathAtom / GlobalPlaceholder
  Parser<PathElement> intermediatePathAtom() => [
        ref0(ebmlPathAtom),
        ref0(globalPlaceholder),
      ].toChoiceParser();

  /// EBMLLastParent         = EBMLPathAtom / GlobalPlaceholder
  Parser<PathElement> ebmlLastParent() => [
        ref0(ebmlPathAtom),
        ref0(globalPlaceholder),
      ].toChoiceParser();

  /// EBMLPathAtom           = [IsRecursive] EBMLAtomName PathDelimiter
  Parser<PathAtom> ebmlPathAtom() => (
        ref0(isRecursive).optional(),
        ref0(ebmlAtomName),
        ref0(pathDelimiter),
      ).toSequenceParser().map(
          (value) => PathAtom(name: value.$2, isRecursive: value.$1 != null));

  /// EBMLElement            = [IsRecursive] EBMLAtomName
  Parser<PathAtom> ebmlElement() => (
        ref0(isRecursive).optional(),
        ref0(ebmlAtomName),
      ).toSequenceParser().map(
          (value) => PathAtom(name: value.$2, isRecursive: value.$1 != null));

  /// PathDelimiter          = "\"
  Parser<String> pathDelimiter() => char(r'\');

  /// IsRecursive            = "+"
  Parser<String> isRecursive() => char('+');

  /// EBMLAtomName           = ALPHA / DIGIT 0*EBMLNameChar
  Parser<String> ebmlAtomName() => [
        [ref0(letter), ref0(digit)].toChoiceParser().map((_) => [_]),
        ref0(ebmlNameChar).star(),
      ].toSequenceParser().map(_flatten).map(_join);

  /// EBMLNameChar           = ALPHA / DIGIT / "-" / "."
  Parser<String> ebmlNameChar() => [
        ref0(letter),
        ref0(digit),
        char('-'),
        char('.'),
      ].toChoiceParser();

  /// GlobalPlaceholder      = "(" GlobalParentOccurrence "\)"
  Parser<GlobalPlaceholder> globalPlaceholder() => (
        char('('),
        ref0(globalParentOccurrence),
        string(r'\)'),
      ).toSequenceParser().map((value) => _limitsToGlobalPlaceHolder(value.$2));

  /// GlobalParentOccurrence = [PathMinOccurrence] "-" [PathMaxOccurrence]
  Parser<(int?, int?)> globalParentOccurrence() => (
        ref0(pathMinOccurrence).optional(),
        char('-'),
        ref0(pathMaxOccurrence),
      ).toSequenceParser().map((value) => (value.$1, value.$3));

  /// PathMinOccurrence      = 1*DIGIT ; no upper limit
  Parser<int> pathMinOccurrence() => ref0(digit).plusString().map(int.parse);

  /// PathMaxOccurrence      = 1*DIGIT ; no upper limit
  Parser<int> pathMaxOccurrence() => ref0(digit).plusString().map(int.parse);
}
