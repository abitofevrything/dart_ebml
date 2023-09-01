import 'package:ebml/ebml.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  test('EbmlSchemaDecoder', () {
    for (final schema in [example, matroska]) {
      final decoder = EbmlSchemaDecoder();
      final document = XmlDocument.parse(schema);

      expect(() => decoder.convert(document), returnsNormally);
    }
  });
}

const example = r'''<?xml version="1.0" encoding="utf-8"?>
<EBMLSchema xmlns="urn:ietf:rfc:8794"
  docType="files-in-ebml-demo" version="1">
 <!-- constraints to the range of two EBML Header Elements -->
 <element name="EBMLReadVersion" path="\EBML\EBMLReadVersion"
   id="0x42F7" minOccurs="1" maxOccurs="1" range="1" default="1"
   type="uinteger"/>
 <element name="EBMLMaxSizeLength"
   path="\EBML\EBMLMaxSizeLength" id="0x42F3" minOccurs="1"
   maxOccurs="1" range="8" default="8" type="uinteger"/>
 <!-- Root Element-->
 <element name="Files" path="\Files" id="0x1946696C"
   type="master">
  <documentation lang="en" 
    purpose="definition">Container of data and
  attributes representing one or many files.</documentation>
 </element>
 <element name="File" path="\Files\File" id="0x6146"
   type="master" minOccurs="1">
  <documentation lang="en" purpose="definition">
    An attached file.
  </documentation>
 </element>
 <element name="FileName" path="\Files\File\FileName"
   id="0x614E" type="utf-8"
   minOccurs="1">
  <documentation lang="en" purpose="definition">
    Filename of the attached file.
  </documentation>
 </element>
 <element name="MimeType" path="\Files\File\MimeType"
   id="0x464D" type="string"
     minOccurs="1">
  <documentation lang="en" purpose="definition">
    MIME type of the file.
  </documentation>
 </element>
 <element name="ModificationTimestamp"
   path="\Files\File\ModificationTimestamp" id="0x4654"
   type="date" minOccurs="1">
  <documentation lang="en" purpose="definition">
    Modification timestamp of the file.
  </documentation>
 </element>
 <element name="Data" path="\Files\File\Data" id="0x4664" 
   type="binary" minOccurs="1">
  <documentation lang="en" purpose="definition">
    The data of the file.
  </documentation>
 </element>
</EBMLSchema>''';

const matroska =
    r'''<EBMLSchema xmlns="urn:ietf:rfc:8794" docType="matroska" version="4">
  <!-- constraints on EBML Header Elements -->
  <element name="EBMLMaxIDLength" path="\EBML\EBMLMaxIDLength" id="0x42F2" type="uinteger" range="4" default="4" minOccurs="1" maxOccurs="1"/>
  <element name="EBMLMaxSizeLength" path="\EBML\EBMLMaxSizeLength" id="0x42F3" type="uinteger" range="1-8" default="8" minOccurs="1" maxOccurs="1"/>
  <!-- Root Element-->
  <element name="Segment" path="\Segment" id="0x18538067" type="master" minOccurs="1" maxOccurs="1" unknownsizeallowed="1">
    <documentation lang="en" purpose="definition">The Root Element that contains all other Top-Level Elements; see (#data-layout).</documentation>
  </element>
  <element name="SeekHead" path="\Segment\SeekHead" id="0x114D9B74" type="master" maxOccurs="2">
    <documentation lang="en" purpose="definition">Contains seeking information of Top-Level Elements; see (#data-layout).</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="Seek" path="\Segment\SeekHead\Seek" id="0x4DBB" type="master" minOccurs="1">
    <documentation lang="en" purpose="definition">Contains a single seek entry to an EBML Element.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="SeekID" path="\Segment\SeekHead\Seek\SeekID" id="0x53AB" type="binary" length="4" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The binary EBML ID of a Top-Level Element.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="SeekPosition" path="\Segment\SeekHead\Seek\SeekPosition" id="0x53AC" type="uinteger" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The Segment Position ((#segment-position)) of a Top-Level Element.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="Info" path="\Segment\Info" id="0x1549A966" type="master" minOccurs="1" maxOccurs="1" recurring="1">
    <documentation lang="en" purpose="definition">Contains general information about the Segment.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="SegmentUUID" path="\Segment\Info\SegmentUUID" id="0x73A4" type="binary" length="16" maxOccurs="1">
    <documentation lang="en" purpose="definition">A randomly generated unique ID to identify the Segment amongst many others (128 bits). It is equivalent to a UUID v4 [@!RFC4122] with all bits randomly (or pseudo-randomly) chosen.  An actual UUID v4 value, where some bits are not random, **MAY** also be used.</documentation>
    <documentation lang="en" purpose="usage notes">If the Segment is a part of a Linked Segment, then this Element is **REQUIRED**.
The value of the unique ID **MUST** contain at least one bit set to 1.</documentation>
    <extension type="libmatroska" cppname="SegmentUID"/>
  </element>
  <element name="SegmentFilename" path="\Segment\Info\SegmentFilename" id="0x7384" type="utf-8" maxOccurs="1">
    <documentation lang="en" purpose="definition">A filename corresponding to this Segment.</documentation>
  </element>
  <element name="PrevUUID" path="\Segment\Info\PrevUUID" id="0x3CB923" type="binary" length="16" maxOccurs="1">
    <documentation lang="en" purpose="definition">An ID to identify the previous Segment of a Linked Segment.</documentation>
    <documentation lang="en" purpose="usage notes">If the Segment is a part of a Linked Segment that uses Hard Linking ((#hard-linking)),
then either the PrevUUID or the NextUUID Element is **REQUIRED**. If a Segment contains a PrevUUID but not a NextUUID,
then it **MAY** be considered as the last Segment of the Linked Segment. The PrevUUID **MUST NOT** be equal to the SegmentUUID.</documentation>
    <extension type="libmatroska" cppname="PrevUID"/>
  </element>
  <element name="PrevFilename" path="\Segment\Info\PrevFilename" id="0x3C83AB" type="utf-8" maxOccurs="1">
    <documentation lang="en" purpose="definition">A filename corresponding to the file of the previous Linked Segment.</documentation>
    <documentation lang="en" purpose="usage notes">Provision of the previous filename is for display convenience,
but PrevUUID **SHOULD** be considered authoritative for identifying the previous Segment in a Linked Segment.</documentation>
  </element>
  <element name="NextUUID" path="\Segment\Info\NextUUID" id="0x3EB923" type="binary" length="16" maxOccurs="1">
    <documentation lang="en" purpose="definition">An ID to identify the next Segment of a Linked Segment.</documentation>
    <documentation lang="en" purpose="usage notes">If the Segment is a part of a Linked Segment that uses Hard Linking ((#hard-linking)),
then either the PrevUUID or the NextUUID Element is **REQUIRED**. If a Segment contains a NextUUID but not a PrevUUID,
then it **MAY** be considered as the first Segment of the Linked Segment. The NextUUID **MUST NOT** be equal to the SegmentUUID.</documentation>
    <extension type="libmatroska" cppname="NextUID"/>
  </element>
  <element name="NextFilename" path="\Segment\Info\NextFilename" id="0x3E83BB" type="utf-8" maxOccurs="1">
    <documentation lang="en" purpose="definition">A filename corresponding to the file of the next Linked Segment.</documentation>
    <documentation lang="en" purpose="usage notes">Provision of the next filename is for display convenience,
but NextUUID **SHOULD** be considered authoritative for identifying the Next Segment.</documentation>
  </element>
  <element name="SegmentFamily" path="\Segment\Info\SegmentFamily" id="0x4444" type="binary" length="16">
    <documentation lang="en" purpose="definition">A unique ID that all Segments of a Linked Segment **MUST** share (128 bits). It is equivalent to a UUID v4 [@!RFC4122] with all bits randomly (or pseudo-randomly) chosen. An actual UUID v4 value, where some bits are not random, **MAY** also be used.</documentation>
    <documentation lang="en" purpose="usage notes">If the Segment Info contains a `ChapterTranslate` element, this Element is **REQUIRED**.</documentation>
  </element>
  <element name="ChapterTranslate" path="\Segment\Info\ChapterTranslate" id="0x6924" type="master">
    <documentation lang="en" purpose="definition">The mapping between this `Segment` and a segment value in the given Chapter Codec.</documentation>
    <documentation lang="en" purpose="rationale">Chapter Codec may need to address different segments, but they may not know of the way to identify such segment when stored in Matroska.
This element and its child elements add a way to map the internal segments known to the Chapter Codec to the Segment IDs in Matroska.
This allows remuxing a file with Chapter Codec without changing the content of the codec data, just the Segment mapping.</documentation>
  </element>
  <element name="ChapterTranslateID" path="\Segment\Info\ChapterTranslate\ChapterTranslateID" id="0x69A5" type="binary" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The binary value used to represent this Segment in the chapter codec data.
The format depends on the ChapProcessCodecID used; see (#chapprocesscodecid-element).</documentation>
  </element>
  <element name="ChapterTranslateCodec" path="\Segment\Info\ChapterTranslate\ChapterTranslateCodec" id="0x69BF" type="uinteger" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">This `ChapterTranslate` applies to this chapter codec of the given chapter edition(s); see (#chapprocesscodecid-element).</documentation>
    <restriction>
      <enum value="0" label="Matroska Script">
        <documentation lang="en" purpose="definition">Chapter commands using the Matroska Script codec.</documentation>
      </enum>
      <enum value="1" label="DVD-menu">
        <documentation lang="en" purpose="definition">Chapter commands using the DVD-like codec.</documentation>
      </enum>
    </restriction>
  </element>
  <element name="ChapterTranslateEditionUID" path="\Segment\Info\ChapterTranslate\ChapterTranslateEditionUID" id="0x69FC" type="uinteger">
    <documentation lang="en" purpose="definition">Specify a chapter edition UID on which this `ChapterTranslate` applies.</documentation>
    <documentation lang="en" purpose="usage notes">When no `ChapterTranslateEditionUID` is specified in the `ChapterTranslate`, the `ChapterTranslate` applies to all chapter editions found in the Segment using the given `ChapterTranslateCodec`.</documentation>
  </element>
  <element name="TimestampScale" path="\Segment\Info\TimestampScale" id="0x2AD7B1" type="uinteger" range="not 0" default="1000000" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Base unit for Segment Ticks and Track Ticks, in nanoseconds. A TimestampScale value of 1000000 means scaled timestamps in the Segment are expressed in milliseconds; see (#timestamps) on how to interpret timestamps.</documentation>
    <extension type="libmatroska" cppname="TimecodeScale"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="Duration" path="\Segment\Info\Duration" id="0x4489" type="float" range="&gt; 0x0p+0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Duration of the Segment, expressed in Segment Ticks which is based on TimestampScale; see (#timestamp-ticks).</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="DateUTC" path="\Segment\Info\DateUTC" id="0x4461" type="date" maxOccurs="1">
    <documentation lang="en" purpose="definition">The date and time that the Segment was created by the muxing application or library.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="Title" path="\Segment\Info\Title" id="0x7BA9" type="utf-8" maxOccurs="1">
    <documentation lang="en" purpose="definition">General name of the Segment.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="MuxingApp" path="\Segment\Info\MuxingApp" id="0x4D80" type="utf-8" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Muxing application or library (example: "libmatroska-0.4.3").</documentation>
    <documentation lang="en" purpose="usage notes">Include the full name of the application or library followed by the version number.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="WritingApp" path="\Segment\Info\WritingApp" id="0x5741" type="utf-8" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Writing application (example: "mkvmerge-0.3.3").</documentation>
    <documentation lang="en" purpose="usage notes">Include the full name of the application followed by the version number.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="Cluster" path="\Segment\Cluster" id="0x1F43B675" type="master" unknownsizeallowed="1">
    <documentation lang="en" purpose="definition">The Top-Level Element containing the (monolithic) Block structure.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="Timestamp" path="\Segment\Cluster\Timestamp" id="0xE7" type="uinteger" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Absolute timestamp of the cluster, expressed in Segment Ticks which is based on TimestampScale; see (#timestamp-ticks).</documentation>
    <documentation lang="en" purpose="usage notes">This element **SHOULD** be the first child element of the Cluster it belongs to,
or the second if that Cluster contains a CRC-32 element ((#crc-32)).</documentation>
    <extension type="libmatroska" cppname="ClusterTimecode"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="SilentTracks" path="\Segment\Cluster\SilentTracks" id="0x5854" type="master" minver="0" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The list of tracks that are not used in that part of the stream.
It is useful when using overlay tracks on seeking or to decide what track to use.</documentation>
    <extension type="libmatroska" cppname="ClusterSilentTracks"/>
  </element>
  <element name="SilentTrackNumber" path="\Segment\Cluster\SilentTracks\SilentTrackNumber" id="0x58D7" type="uinteger" minver="0" maxver="0">
    <documentation lang="en" purpose="definition">One of the track number that are not used from now on in the stream.
It could change later if not specified as silent in a further Cluster.</documentation>
    <extension type="libmatroska" cppname="ClusterSilentTrackNumber"/>
  </element>
  <element name="Position" path="\Segment\Cluster\Position" id="0xA7" type="uinteger" maxver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">The Segment Position of the Cluster in the Segment (0 in live streams).
It might help to resynchronise offset on damaged streams.</documentation>
    <extension type="libmatroska" cppname="ClusterPosition"/>
  </element>
  <element name="PrevSize" path="\Segment\Cluster\PrevSize" id="0xAB" type="uinteger" maxOccurs="1">
    <documentation lang="en" purpose="definition">Size of the previous Cluster, in octets. Can be useful for backward playing.</documentation>
    <extension type="libmatroska" cppname="ClusterPrevSize"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="SimpleBlock" path="\Segment\Cluster\SimpleBlock" id="0xA3" type="binary" minver="2">
    <documentation lang="en" purpose="definition">Similar to Block, see (#block-structure), but without all the extra information,
mostly used to reduced overhead when no extra feature is needed; see (#simpleblock-structure) on SimpleBlock Structure.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="divx.com" divx="1"/>
  </element>
  <element name="BlockGroup" path="\Segment\Cluster\BlockGroup" id="0xA0" type="master">
    <documentation lang="en" purpose="definition">Basic container of information containing a single Block and information specific to that Block.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="Block" path="\Segment\Cluster\BlockGroup\Block" id="0xA1" type="binary" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Block containing the actual data to be rendered and a timestamp relative to the Cluster Timestamp;
see (#block-structure) on Block Structure.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="BlockVirtual" path="\Segment\Cluster\BlockGroup\BlockVirtual" id="0xA2" type="binary" minver="0" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">A Block with no data. It must be stored in the stream at the place the real Block would be in display order.
</documentation>
  </element>
  <element name="BlockAdditions" path="\Segment\Cluster\BlockGroup\BlockAdditions" id="0x75A1" type="master" maxOccurs="1">
    <documentation lang="en" purpose="definition">Contain additional binary data to complete the main one; see Codec BlockAdditions section of [@?MatroskaCodec] for more information.
An EBML parser that has no knowledge of the Block structure could still see and use/skip these data.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="BlockMore" path="\Segment\Cluster\BlockGroup\BlockAdditions\BlockMore" id="0xA6" type="master" minOccurs="1">
    <documentation lang="en" purpose="definition">Contain the BlockAdditional and some parameters.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="BlockAdditional" path="\Segment\Cluster\BlockGroup\BlockAdditions\BlockMore\BlockAdditional" id="0xA5" type="binary" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Interpreted by the codec as it wishes (using the BlockAddID).</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="BlockAddID" path="\Segment\Cluster\BlockGroup\BlockAdditions\BlockMore\BlockAddID" id="0xEE" type="uinteger" range="not 0" default="1" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">An ID to identify how to interpret the BlockAdditional data; see Codec BlockAdditions section of [@?MatroskaCodec] for more information.
A value of 1 indicates that the meaning of the BlockAdditional data is defined by the codec.
Any other value indicates the meaning of the BlockAdditional data is found in the BlockAddIDType found in the TrackEntry.</documentation>
    <documentation lang="en" purpose="usage notes">Each BlockAddID value **MUST** be unique between all BlockMore elements found in a BlockAdditions.</documentation>
    <documentation lang="en" purpose="usage notes">To keep MaxBlockAdditionID as low as possible, small values **SHOULD** be used.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="BlockDuration" path="\Segment\Cluster\BlockGroup\BlockDuration" id="0x9B" type="uinteger" maxOccurs="1">
    <documentation lang="en" purpose="definition">The duration of the Block, expressed in Track Ticks; see (#timestamp-ticks).
The BlockDuration Element can be useful at the end of a Track to define the duration of the last frame (as there is no subsequent Block available),
or when there is a break in a track like for subtitle tracks.</documentation>
    <implementation_note note_attribute="minOccurs">BlockDuration **MUST** be set (minOccurs=1) if the associated TrackEntry stores a DefaultDuration value.</implementation_note>
    <implementation_note note_attribute="default">When not written and with no DefaultDuration, the value is assumed to be the difference between the timestamp of this Block and the timestamp of the next Block in "display" order (not coding order).</implementation_note>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="ReferencePriority" path="\Segment\Cluster\BlockGroup\ReferencePriority" id="0xFA" type="uinteger" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">This frame is referenced and has the specified cache priority.
In cache only a frame of the same or higher priority can replace this frame. A value of 0 means the frame is not referenced.</documentation>
  </element>
  <element name="ReferenceBlock" path="\Segment\Cluster\BlockGroup\ReferenceBlock" id="0xFB" type="integer">
    <documentation lang="en" purpose="definition">A timestamp value, relative to the timestamp of the Block in this BlockGroup, expressed in Track Ticks; see (#timestamp-ticks).
This is used to reference other frames necessary to decode this frame.
The relative value **SHOULD** correspond to a valid `Block` this `Block` depends on.
Historically Matroska Writer didn't write the actual `Block(s)` this `Block` depends on, but *some* `Block` in the past.

The value "0" **MAY** also be used to signify this `Block` cannot be decoded on its own, but without knownledge of which `Block` is necessary. In this case, other `ReferenceBlock` **MUST NOT** be found in the same `BlockGroup`.

If the `BlockGroup` doesn't have any `ReferenceBlock` element, then the `Block` it contains can be decoded without using any other `Block` data.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="ReferenceVirtual" path="\Segment\Cluster\BlockGroup\ReferenceVirtual" id="0xFD" type="integer" minver="0" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The Segment Position of the data that would otherwise be in position of the virtual block.</documentation>
  </element>
  <element name="CodecState" path="\Segment\Cluster\BlockGroup\CodecState" id="0xA4" type="binary" minver="2" maxOccurs="1">
    <documentation lang="en" purpose="definition">The new codec state to use. Data interpretation is private to the codec.
This information **SHOULD** always be referenced by a seek entry.</documentation>
  </element>
  <element name="DiscardPadding" path="\Segment\Cluster\BlockGroup\DiscardPadding" id="0x75A2" type="integer" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">Duration of the silent data added to the Block, expressed in Matroska Ticks -- i.e., in nanoseconds; see (#timestamp-ticks)
(padding at the end of the Block for positive value, at the beginning of the Block for negative value).
The duration of DiscardPadding is not calculated in the duration of the TrackEntry and **SHOULD** be discarded during playback.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="Slices" path="\Segment\Cluster\BlockGroup\Slices" id="0x8E" type="master" minver="0" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Contains slices description.</documentation>
  </element>
  <element name="TimeSlice" path="\Segment\Cluster\BlockGroup\Slices\TimeSlice" id="0xE8" type="master" minver="0" maxver="0">
    <documentation lang="en" purpose="definition">Contains extra time information about the data contained in the Block.
Being able to interpret this Element is not required for playback.</documentation>
  </element>
  <element name="LaceNumber" path="\Segment\Cluster\BlockGroup\Slices\TimeSlice\LaceNumber" id="0xCC" type="uinteger" minver="0" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The reverse number of the frame in the lace (0 is the last frame, 1 is the next to last, etc.).
Being able to interpret this Element is not required for playback.</documentation>
    <extension type="libmatroska" cppname="SliceLaceNumber"/>
  </element>
  <element name="FrameNumber" path="\Segment\Cluster\BlockGroup\Slices\TimeSlice\FrameNumber" id="0xCD" type="uinteger" minver="0" maxver="0" default="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The number of the frame to generate from this lace with this delay
(allow you to generate many frames from the same Block/Frame).</documentation>
    <extension type="libmatroska" cppname="SliceFrameNumber"/>
  </element>
  <element name="BlockAdditionID" path="\Segment\Cluster\BlockGroup\Slices\TimeSlice\BlockAdditionID" id="0xCB" type="uinteger" minver="0" maxver="0" default="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The ID of the BlockAdditional Element (0 is the main Block).</documentation>
    <extension type="libmatroska" cppname="SliceBlockAddID"/>
  </element>
  <element name="Delay" path="\Segment\Cluster\BlockGroup\Slices\TimeSlice\Delay" id="0xCE" type="uinteger" minver="0" maxver="0" default="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The delay to apply to the Element, expressed in Track Ticks; see (#timestamp-ticks).</documentation>
    <extension type="libmatroska" cppname="SliceDelay"/>
  </element>
  <element name="SliceDuration" path="\Segment\Cluster\BlockGroup\Slices\TimeSlice\SliceDuration" id="0xCF" type="uinteger" minver="0" maxver="0" default="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The duration to apply to the Element, expressed in Track Ticks; see (#timestamp-ticks).</documentation>
  </element>
  <element name="ReferenceFrame" path="\Segment\Cluster\BlockGroup\ReferenceFrame" id="0xC8" type="master" minver="0" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Contains information about the last reference frame. See [@?DivXTrickTrack].</documentation>
    <extension type="divx.com" divx="1"/>
  </element>
  <element name="ReferenceOffset" path="\Segment\Cluster\BlockGroup\ReferenceFrame\ReferenceOffset" id="0xC9" type="uinteger" minver="0" maxver="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The relative offset, in bytes, from the previous BlockGroup element for this Smooth FF/RW video track to the containing BlockGroup element. See [@?DivXTrickTrack].</documentation>
    <extension type="divx.com" divx="1"/>
  </element>
  <element name="ReferenceTimestamp" path="\Segment\Cluster\BlockGroup\ReferenceFrame\ReferenceTimestamp" id="0xCA" type="uinteger" minver="0" maxver="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The timestamp of the BlockGroup pointed to by ReferenceOffset, expressed in Track Ticks; see (#timestamp-ticks). See [@?DivXTrickTrack].</documentation>
    <extension type="libmatroska" cppname="ReferenceTimeCode"/>
    <extension type="divx.com" divx="1"/>
  </element>
  <element name="EncryptedBlock" path="\Segment\Cluster\EncryptedBlock" id="0xAF" type="binary" minver="0" maxver="0">
    <documentation lang="en" purpose="definition">Similar to SimpleBlock, see (#simpleblock-structure),
but the data inside the Block are Transformed (encrypt and/or signed).</documentation>
  </element>
  <element name="Tracks" path="\Segment\Tracks" id="0x1654AE6B" type="master" maxOccurs="1" recurring="1">
    <documentation lang="en" purpose="definition">A Top-Level Element of information with many tracks described.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="TrackEntry" path="\Segment\Tracks\TrackEntry" id="0xAE" type="master" minOccurs="1">
    <documentation lang="en" purpose="definition">Describes a track with all Elements.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="TrackNumber" path="\Segment\Tracks\TrackEntry\TrackNumber" id="0xD7" type="uinteger" range="not 0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The track number as used in the Block Header.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="TrackUID" path="\Segment\Tracks\TrackEntry\TrackUID" id="0x73C5" type="uinteger" range="not 0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">A unique ID to identify the Track.</documentation>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="TrackType" path="\Segment\Tracks\TrackEntry\TrackType" id="0x83" type="uinteger" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The `TrackType` defines the type of each frame found in the Track.
The value **SHOULD** be stored on 1 octet.</documentation>
    <restriction>
      <enum value="1" label="video">
        <documentation lang="en" purpose="definition">An image.</documentation>
      </enum>
      <enum value="2" label="audio">
        <documentation lang="en" purpose="definition">Audio samples.</documentation>
      </enum>
      <enum value="3" label="complex">
        <documentation lang="en" purpose="definition">A mix of different other TrackType. The codec needs to define how the `Matroska Player` should interpret such data.</documentation>
      </enum>
      <enum value="16" label="logo">
        <documentation lang="en" purpose="definition">An image to be rendered over the video track(s).</documentation>
      </enum>
      <enum value="17" label="subtitle">
        <documentation lang="en" purpose="definition">Subtitle or closed caption data to be rendered over the video track(s).</documentation>
      </enum>
      <enum value="18" label="buttons">
        <documentation lang="en" purpose="definition">Interactive button(s) to be rendered over the video track(s).</documentation>
      </enum>
      <enum value="32" label="control">
        <documentation lang="en" purpose="definition">Metadata used to control the player of the `Matroska Player`.</documentation>
      </enum>
      <enum value="33" label="metadata">
        <documentation lang="en" purpose="definition">Timed metadata that can be passed on to the `Matroska Player`.</documentation>
      </enum>
    </restriction>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="FlagEnabled" path="\Segment\Tracks\TrackEntry\FlagEnabled" id="0xB9" type="uinteger" minver="2" range="0-1" default="1" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Set to 1 if the track is usable. It is possible to turn a not usable track into a usable track using chapter codecs or control tracks.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="TrackFlagEnabled"/>
  </element>
  <element name="FlagDefault" path="\Segment\Tracks\TrackEntry\FlagDefault" id="0x88" type="uinteger" range="0-1" default="1" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Set if that track (audio, video or subs) is eligible for automatic selection by the player; see (#default-track-selection) for more details.</documentation>
    <extension type="libmatroska" cppname="TrackFlagDefault"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="FlagForced" path="\Segment\Tracks\TrackEntry\FlagForced" id="0x55AA" type="uinteger" range="0-1" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Applies only to subtitles. Set if that track is eligible for automatic selection by the player if it matches the user's language preference,
even if the user's preferences would normally not enable subtitles with the selected audio track;
this can be used for tracks containing only translations of foreign-language audio or onscreen text.
See (#default-track-selection) for more details.</documentation>
    <extension type="libmatroska" cppname="TrackFlagForced"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="FlagHearingImpaired" path="\Segment\Tracks\TrackEntry\FlagHearingImpaired" id="0x55AB" type="uinteger" minver="4" range="0-1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Set to 1 if and only if that track is suitable for users with hearing impairments.</documentation>
  </element>
  <element name="FlagVisualImpaired" path="\Segment\Tracks\TrackEntry\FlagVisualImpaired" id="0x55AC" type="uinteger" minver="4" range="0-1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Set to 1 if and only if that track is suitable for users with visual impairments.</documentation>
  </element>
  <element name="FlagTextDescriptions" path="\Segment\Tracks\TrackEntry\FlagTextDescriptions" id="0x55AD" type="uinteger" minver="4" range="0-1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Set to 1 if and only if that track contains textual descriptions of video content.</documentation>
  </element>
  <element name="FlagOriginal" path="\Segment\Tracks\TrackEntry\FlagOriginal" id="0x55AE" type="uinteger" minver="4" range="0-1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Set to 1 if and only if that track is in the content's original language.</documentation>
  </element>
  <element name="FlagCommentary" path="\Segment\Tracks\TrackEntry\FlagCommentary" id="0x55AF" type="uinteger" minver="4" range="0-1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Set to 1 if and only if that track contains commentary.</documentation>
  </element>
  <element name="FlagLacing" path="\Segment\Tracks\TrackEntry\FlagLacing" id="0x9C" type="uinteger" range="0-1" default="1" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Set to 1 if the track **MAY** contain blocks using lacing. When set to 0 all blocks **MUST** have their lacing flags set to No lacing; see (#block-lacing) on Block Lacing.</documentation>
    <extension type="libmatroska" cppname="TrackFlagLacing"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="MinCache" path="\Segment\Tracks\TrackEntry\MinCache" id="0x6DE7" type="uinteger" minver="0" maxver="0" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The minimum number of frames a player should be able to cache during playback.
If set to 0, the reference pseudo-cache system is not used.</documentation>
    <extension type="libmatroska" cppname="TrackMinCache"/>
  </element>
  <element name="MaxCache" path="\Segment\Tracks\TrackEntry\MaxCache" id="0x6DF8" type="uinteger" minver="0" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The maximum cache size necessary to store referenced frames in and the current frame.
0 means no cache is needed.</documentation>
    <extension type="libmatroska" cppname="TrackMaxCache"/>
  </element>
  <element name="DefaultDuration" path="\Segment\Tracks\TrackEntry\DefaultDuration" id="0x23E383" type="uinteger" range="not 0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Number of nanoseconds per frame, expressed in Matroska Ticks -- i.e., in nanoseconds; see (#timestamp-ticks)
(frame in the Matroska sense -- one Element put into a (Simple)Block).</documentation>
    <extension type="libmatroska" cppname="TrackDefaultDuration"/>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="DefaultDecodedFieldDuration" path="\Segment\Tracks\TrackEntry\DefaultDecodedFieldDuration" id="0x234E7A" type="uinteger" minver="4" range="not 0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The period between two successive fields at the output of the decoding process, expressed in Matroska Ticks -- i.e., in nanoseconds; see (#timestamp-ticks).
see (#defaultdecodedfieldduration) for more information</documentation>
    <extension type="libmatroska" cppname="TrackDefaultDecodedFieldDuration"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="TrackTimestampScale" path="\Segment\Tracks\TrackEntry\TrackTimestampScale" id="0x23314F" type="float" maxver="3" range="&gt; 0x0p+0" default="0x1p+0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The scale to apply on this track to work at normal speed in relation with other tracks
(mostly used to adjust video speed when the audio length differs).</documentation>
    <extension type="libmatroska" cppname="TrackTimecodeScale"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="TrackOffset" path="\Segment\Tracks\TrackEntry\TrackOffset" id="0x537F" type="integer" minver="0" maxver="0" default="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">A value to add to the Block's Timestamp, expressed in Matroska Ticks -- i.e., in nanoseconds; see (#timestamp-ticks).
This can be used to adjust the playback offset of a track.</documentation>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="MaxBlockAdditionID" path="\Segment\Tracks\TrackEntry\MaxBlockAdditionID" id="0x55EE" type="uinteger" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The maximum value of BlockAddID ((#blockaddid-element)).
A value 0 means there is no BlockAdditions ((#blockadditions-element)) for this track.</documentation>
  </element>
  <element name="BlockAdditionMapping" path="\Segment\Tracks\TrackEntry\BlockAdditionMapping" id="0x41E4" type="master" minver="4">
    <documentation lang="en" purpose="definition">Contains elements that extend the track format, by adding content either to each frame,
with BlockAddID ((#blockaddid-element)), or to the track as a whole
with BlockAddIDExtraData.</documentation>
  </element>
  <element name="BlockAddIDValue" path="\Segment\Tracks\TrackEntry\BlockAdditionMapping\BlockAddIDValue" id="0x41F0" type="uinteger" minver="4" range="&gt;=2" maxOccurs="1">
    <documentation lang="en" purpose="definition">If the track format extension needs content beside frames,
the value refers to the BlockAddID ((#blockaddid-element)), value being described.</documentation>
    <documentation lang="en" purpose="usage notes">To keep MaxBlockAdditionID as low as possible, small values **SHOULD** be used.</documentation>
  </element>
  <element name="BlockAddIDName" path="\Segment\Tracks\TrackEntry\BlockAdditionMapping\BlockAddIDName" id="0x41A4" type="string" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">A human-friendly name describing the type of BlockAdditional data,
as defined by the associated Block Additional Mapping.</documentation>
  </element>
  <element name="BlockAddIDType" path="\Segment\Tracks\TrackEntry\BlockAdditionMapping\BlockAddIDType" id="0x41E7" type="uinteger" minver="4" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Stores the registered identifier of the Block Additional Mapping
to define how the BlockAdditional data should be handled.</documentation>
    <documentation lang="en" purpose="usage notes">If BlockAddIDType is 0, the BlockAddIDValue and corresponding BlockAddID values **MUST** be 1.</documentation>
  </element>
  <element name="BlockAddIDExtraData" path="\Segment\Tracks\TrackEntry\BlockAdditionMapping\BlockAddIDExtraData" id="0x41ED" type="binary" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">Extra binary data that the BlockAddIDType can use to interpret the BlockAdditional data.
The interpretation of the binary data depends on the BlockAddIDType value and the corresponding Block Additional Mapping.</documentation>
  </element>
  <element name="Name" path="\Segment\Tracks\TrackEntry\Name" id="0x536E" type="utf-8" maxOccurs="1">
    <documentation lang="en" purpose="definition">A human-readable track name.</documentation>
    <extension type="libmatroska" cppname="TrackName"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="Language" path="\Segment\Tracks\TrackEntry\Language" id="0x22B59C" type="string" default="eng" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The language of the track,
in the Matroska languages form; see (#language-codes) on language codes.
This Element **MUST** be ignored if the LanguageBCP47 Element is used in the same TrackEntry.</documentation>
    <extension type="libmatroska" cppname="TrackLanguage"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="LanguageBCP47" path="\Segment\Tracks\TrackEntry\LanguageBCP47" id="0x22B59D" type="string" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">The language of the track,
in the [@!BCP47] form; see (#language-codes) on language codes.
If this Element is used, then any Language Elements used in the same TrackEntry **MUST** be ignored.</documentation>
    <extension type="libmatroska" cppname="LanguageIETF"/>
  </element>
  <element name="CodecID" path="\Segment\Tracks\TrackEntry\CodecID" id="0x86" type="string" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">An ID corresponding to the codec,
see [@?MatroskaCodec] for more info.</documentation>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="CodecPrivate" path="\Segment\Tracks\TrackEntry\CodecPrivate" id="0x63A2" type="binary" maxOccurs="1">
    <documentation lang="en" purpose="definition">Private data only known to the codec.</documentation>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="CodecName" path="\Segment\Tracks\TrackEntry\CodecName" id="0x258688" type="utf-8" maxOccurs="1">
    <documentation lang="en" purpose="definition">A human-readable string specifying the codec.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="AttachmentLink" path="\Segment\Tracks\TrackEntry\AttachmentLink" id="0x7446" type="uinteger" maxver="3" range="not 0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The UID of an attachment that is used by this codec.</documentation>
    <documentation lang="en" purpose="usage notes">The value **MUST** match the `FileUID` value of an attachment found in this Segment.</documentation>
    <extension type="libmatroska" cppname="TrackAttachmentLink"/>
  </element>
  <element name="CodecSettings" path="\Segment\Tracks\TrackEntry\CodecSettings" id="0x3A9697" type="utf-8" minver="0" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">A string describing the encoding setting used.</documentation>
  </element>
  <element name="CodecInfoURL" path="\Segment\Tracks\TrackEntry\CodecInfoURL" id="0x3B4040" type="string" minver="0" maxver="0">
    <documentation lang="en" purpose="definition">A URL to find information about the codec used.</documentation>
  </element>
  <element name="CodecDownloadURL" path="\Segment\Tracks\TrackEntry\CodecDownloadURL" id="0x26B240" type="string" minver="0" maxver="0">
    <documentation lang="en" purpose="definition">A URL to download about the codec used.</documentation>
  </element>
  <element name="CodecDecodeAll" path="\Segment\Tracks\TrackEntry\CodecDecodeAll" id="0xAA" type="uinteger" maxver="0" range="0-1" default="1" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Set to 1 if the codec can decode potentially damaged data.</documentation>
  </element>
  <element name="TrackOverlay" path="\Segment\Tracks\TrackEntry\TrackOverlay" id="0x6FAB" type="uinteger" maxver="0">
    <documentation lang="en" purpose="definition">Specify that this track is an overlay track for the Track specified (in the u-integer).
That means when this track has a gap on SilentTracks,
the overlay track should be used instead. The order of multiple TrackOverlay matters, the first one is the one that should be used.
If not found it should be the second, etc.</documentation>
  </element>
  <element name="CodecDelay" path="\Segment\Tracks\TrackEntry\CodecDelay" id="0x56AA" type="uinteger" minver="4" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">CodecDelay is The codec-built-in delay, expressed in Matroska Ticks -- i.e., in nanoseconds; see (#timestamp-ticks).
It represents the amount of codec samples that will be discarded by the decoder during playback.
This timestamp value **MUST** be subtracted from each frame timestamp in order to get the timestamp that will be actually played.
The value **SHOULD** be small so the muxing of tracks with the same actual timestamp are in the same Cluster.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="SeekPreRoll" path="\Segment\Tracks\TrackEntry\SeekPreRoll" id="0x56BB" type="uinteger" minver="4" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">After a discontinuity, SeekPreRoll is the duration of the data
the decoder **MUST** decode before the decoded data is valid, expressed in Matroska Ticks -- i.e., in nanoseconds; see (#timestamp-ticks).</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="TrackTranslate" path="\Segment\Tracks\TrackEntry\TrackTranslate" id="0x6624" type="master">
    <documentation lang="en" purpose="definition">The mapping between this `TrackEntry` and a track value in the given Chapter Codec.</documentation>
    <documentation lang="en" purpose="rationale">Chapter Codec may need to address content in specific track, but they may not know of the way to identify tracks in Matroska.
This element and its child elements add a way to map the internal tracks known to the Chapter Codec to the track IDs in Matroska.
This allows remuxing a file with Chapter Codec without changing the content of the codec data, just the track mapping.</documentation>
  </element>
  <element name="TrackTranslateTrackID" path="\Segment\Tracks\TrackEntry\TrackTranslate\TrackTranslateTrackID" id="0x66A5" type="binary" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The binary value used to represent this `TrackEntry` in the chapter codec data.
The format depends on the `ChapProcessCodecID` used; see (#chapprocesscodecid-element).</documentation>
  </element>
  <element name="TrackTranslateCodec" path="\Segment\Tracks\TrackEntry\TrackTranslate\TrackTranslateCodec" id="0x66BF" type="uinteger" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">This `TrackTranslate` applies to this chapter codec of the given chapter edition(s); see (#chapprocesscodecid-element).</documentation>
    <restriction>
      <enum value="0" label="Matroska Script">
        <documentation lang="en" purpose="definition">Chapter commands using the Matroska Script codec.</documentation>
      </enum>
      <enum value="1" label="DVD-menu">
        <documentation lang="en" purpose="definition">Chapter commands using the DVD-like codec.</documentation>
      </enum>
    </restriction>
  </element>
  <element name="TrackTranslateEditionUID" path="\Segment\Tracks\TrackEntry\TrackTranslate\TrackTranslateEditionUID" id="0x66FC" type="uinteger">
    <documentation lang="en" purpose="definition">Specify a chapter edition UID on which this `TrackTranslate` applies.</documentation>
    <documentation lang="en" purpose="usage notes">When no `TrackTranslateEditionUID` is specified in the `TrackTranslate`, the `TrackTranslate` applies to all chapter editions found in the Segment using the given `TrackTranslateCodec`.</documentation>
  </element>
  <element name="Video" path="\Segment\Tracks\TrackEntry\Video" id="0xE0" type="master" maxOccurs="1">
    <documentation lang="en" purpose="definition">Video settings.</documentation>
    <extension type="libmatroska" cppname="TrackVideo"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="FlagInterlaced" path="\Segment\Tracks\TrackEntry\Video\FlagInterlaced" id="0x9A" type="uinteger" minver="2" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Specify whether the video frames in this track are interlaced.</documentation>
    <restriction>
      <enum value="0" label="undetermined">
        <documentation lang="en" purpose="definition">Unknown status.</documentation>
        <documentation lang="en" purpose="usage notes">This value **SHOULD** be avoided.</documentation>
      </enum>
      <enum value="1" label="interlaced">
        <documentation lang="en" purpose="definition">Interlaced frames.</documentation>
      </enum>
      <enum value="2" label="progressive">
        <documentation lang="en" purpose="definition">No interlacing.</documentation>
      </enum>
    </restriction>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoFlagInterlaced"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="FieldOrder" path="\Segment\Tracks\TrackEntry\Video\FieldOrder" id="0x9D" type="uinteger" minver="4" default="2" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Specify the field ordering of video frames in this track.</documentation>
    <documentation lang="en" purpose="usage notes">If FlagInterlaced is not set to 1, this Element **MUST** be ignored.</documentation>
    <restriction>
      <enum value="0" label="progressive">
        <documentation lang="en" purpose="definition">Interlaced frames.</documentation>
        <documentation lang="en" purpose="usage notes">This value **SHOULD** be avoided, setting FlagInterlaced to 2 is sufficient.</documentation>
      </enum>
      <enum value="1" label="tff">
        <documentation lang="en" purpose="definition">Top field displayed first. Top field stored first.</documentation>
      </enum>
      <enum value="2" label="undetermined">
        <documentation lang="en" purpose="definition">Unknown field order.</documentation>
        <documentation lang="en" purpose="usage notes">This value **SHOULD** be avoided.</documentation>
      </enum>
      <enum value="6" label="bff">
        <documentation lang="en" purpose="definition">Bottom field displayed first. Bottom field stored first.</documentation>
      </enum>
      <enum value="9" label="bff(swapped)">
        <documentation lang="en" purpose="definition">Top field displayed first. Fields are interleaved in storage with the top line of the top field stored first.</documentation>
      </enum>
      <enum value="14" label="tff(swapped)">
        <documentation lang="en" purpose="definition">Bottom field displayed first. Fields are interleaved in storage with the top line of the top field stored first.</documentation>
      </enum>
    </restriction>
    <extension type="libmatroska" cppname="VideoFieldOrder"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="StereoMode" path="\Segment\Tracks\TrackEntry\Video\StereoMode" id="0x53B8" type="uinteger" minver="3" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Stereo-3D video mode. There are some more details in (#multi-planar-and-3d-videos).</documentation>
    <restriction>
      <enum value="0" label="mono"/>
      <enum value="1" label="side by side (left eye first)"/>
      <enum value="2" label="top - bottom (right eye is first)"/>
      <enum value="3" label="top - bottom (left eye is first)"/>
      <enum value="4" label="checkboard (right eye is first)"/>
      <enum value="5" label="checkboard (left eye is first)"/>
      <enum value="6" label="row interleaved (right eye is first)"/>
      <enum value="7" label="row interleaved (left eye is first)"/>
      <enum value="8" label="column interleaved (right eye is first)"/>
      <enum value="9" label="column interleaved (left eye is first)"/>
      <enum value="10" label="anaglyph (cyan/red)"/>
      <enum value="11" label="side by side (right eye first)"/>
      <enum value="12" label="anaglyph (green/magenta)"/>
      <enum value="13" label="both eyes laced in one Block (left eye is first)"/>
      <enum value="14" label="both eyes laced in one Block (right eye is first)"/>
    </restriction>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoStereoMode"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="AlphaMode" path="\Segment\Tracks\TrackEntry\Video\AlphaMode" id="0x53C0" type="uinteger" minver="3" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Indicate whether the BlockAdditional Element with BlockAddID of "1" contains Alpha data, as defined by to the Codec Mapping for the `CodecID`.
Undefined values **SHOULD NOT** be used as the behavior of known implementations is different (considered either as 0 or 1).</documentation>
    <restriction>
      <enum value="0" label="none">
        <documentation lang="en" purpose="definition">The BlockAdditional Element with BlockAddID of "1" does not exist or **SHOULD NOT** be considered as containing such data.</documentation>
      </enum>
      <enum value="1" label="present">
        <documentation lang="en" purpose="definition">The BlockAdditional Element with BlockAddID of "1" contains alpha channel data.</documentation>
      </enum>
    </restriction>

    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoAlphaMode"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="OldStereoMode" path="\Segment\Tracks\TrackEntry\Video\OldStereoMode" id="0x53B9" type="uinteger" maxver="2" maxOccurs="1">
    <documentation lang="en" purpose="definition">Bogus StereoMode value used in old versions of libmatroska.</documentation>
    <documentation lang="en" purpose="usage notes">This Element **MUST NOT** be used. It was an incorrect value used in libmatroska up to 0.9.0.</documentation>
    <restriction>
      <enum value="0" label="mono"/>
      <enum value="1" label="right eye"/>
      <enum value="2" label="left eye"/>
      <enum value="3" label="both eyes"/>
    </restriction>
  </element>
  <element name="PixelWidth" path="\Segment\Tracks\TrackEntry\Video\PixelWidth" id="0xB0" type="uinteger" range="not 0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Width of the encoded video frames in pixels.</documentation>
    <extension type="libmatroska" cppname="VideoPixelWidth"/>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="PixelHeight" path="\Segment\Tracks\TrackEntry\Video\PixelHeight" id="0xBA" type="uinteger" range="not 0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Height of the encoded video frames in pixels.</documentation>
    <extension type="libmatroska" cppname="VideoPixelHeight"/>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="PixelCropBottom" path="\Segment\Tracks\TrackEntry\Video\PixelCropBottom" id="0x54AA" type="uinteger" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The number of video pixels to remove at the bottom of the image.</documentation>
    <extension type="libmatroska" cppname="VideoPixelCropBottom"/>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="PixelCropTop" path="\Segment\Tracks\TrackEntry\Video\PixelCropTop" id="0x54BB" type="uinteger" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The number of video pixels to remove at the top of the image.</documentation>
    <extension type="libmatroska" cppname="VideoPixelCropTop"/>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="PixelCropLeft" path="\Segment\Tracks\TrackEntry\Video\PixelCropLeft" id="0x54CC" type="uinteger" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The number of video pixels to remove on the left of the image.</documentation>
    <extension type="libmatroska" cppname="VideoPixelCropLeft"/>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="PixelCropRight" path="\Segment\Tracks\TrackEntry\Video\PixelCropRight" id="0x54DD" type="uinteger" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The number of video pixels to remove on the right of the image.</documentation>
    <extension type="libmatroska" cppname="VideoPixelCropRight"/>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="DisplayWidth" path="\Segment\Tracks\TrackEntry\Video\DisplayWidth" id="0x54B0" type="uinteger" range="not 0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Width of the video frames to display. Applies to the video frame after cropping (PixelCrop* Elements).</documentation>
    <implementation_note note_attribute="default">If the DisplayUnit of the same TrackEntry is 0, then the default value for DisplayWidth is equal to
PixelWidth - PixelCropLeft - PixelCropRight, else there is no default value.</implementation_note>
    <extension type="libmatroska" cppname="VideoDisplayWidth"/>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="DisplayHeight" path="\Segment\Tracks\TrackEntry\Video\DisplayHeight" id="0x54BA" type="uinteger" range="not 0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Height of the video frames to display. Applies to the video frame after cropping (PixelCrop* Elements).</documentation>
    <implementation_note note_attribute="default">If the DisplayUnit of the same TrackEntry is 0, then the default value for DisplayHeight is equal to
PixelHeight - PixelCropTop - PixelCropBottom, else there is no default value.</implementation_note>
    <extension type="libmatroska" cppname="VideoDisplayHeight"/>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="DisplayUnit" path="\Segment\Tracks\TrackEntry\Video\DisplayUnit" id="0x54B2" type="uinteger" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">How DisplayWidth &amp; DisplayHeight are interpreted.</documentation>
    <restriction>
      <enum value="0" label="pixels"/>
      <enum value="1" label="centimeters"/>
      <enum value="2" label="inches"/>
      <enum value="3" label="display aspect ratio"/>
      <enum value="4" label="unknown"/>
    </restriction>
    <extension type="libmatroska" cppname="VideoDisplayUnit"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="AspectRatioType" path="\Segment\Tracks\TrackEntry\Video\AspectRatioType" id="0x54B3" type="uinteger" minver="0" maxver="0" default="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Specify the possible modifications to the aspect ratio.</documentation>
    <restriction>
      <enum value="0" label="free resizing"/>
      <enum value="1" label="keep aspect ratio"/>
      <enum value="2" label="fixed"/>
    </restriction>
    <extension type="libmatroska" cppname="VideoAspectRatio"/>
  </element>
  <element name="UncompressedFourCC" path="\Segment\Tracks\TrackEntry\Video\UncompressedFourCC" id="0x2EB524" type="binary" length="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">Specify the uncompressed pixel format used for the Track's data as a FourCC.
This value is similar in scope to the biCompression value of AVI's `BITMAPINFO` [@?AVIFormat]. There is no definitive list of FourCC values, nor an official registry. Some common values for YUV pixel formats can be found at [@?MSYUV8], [@?MSYUV16] and [@?FourCC-YUV]. Some common values for uncompressed RGB pixel formats can be found at [@?MSRGB] and [@?FourCC-RGB].</documentation>
    <implementation_note note_attribute="minOccurs">UncompressedFourCC **MUST** be set (minOccurs=1) in TrackEntry, when the CodecID Element of the TrackEntry is set to "V_UNCOMPRESSED".</implementation_note>
    <extension type="libmatroska" cppname="VideoColourSpace"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="GammaValue" path="\Segment\Tracks\TrackEntry\Video\GammaValue" id="0x2FB523" type="float" minver="0" maxver="0" range="&gt; 0x0p+0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Gamma Value.</documentation>
    <extension type="libmatroska" cppname="VideoGamma"/>
  </element>
  <element name="FrameRate" path="\Segment\Tracks\TrackEntry\Video\FrameRate" id="0x2383E3" type="float" minver="0" maxver="0" range="&gt; 0x0p+0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Number of frames per second. This value is Informational only. It is intended for constant frame rate streams, and should not be used for a variable frame rate TrackEntry.</documentation>
    <extension type="libmatroska" cppname="VideoFrameRate"/>
  </element>
  <element name="Colour" path="\Segment\Tracks\TrackEntry\Video\Colour" id="0x55B0" type="master" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">Settings describing the colour format.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoColour"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="MatrixCoefficients" path="\Segment\Tracks\TrackEntry\Video\Colour\MatrixCoefficients" id="0x55B1" type="uinteger" minver="4" default="2" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The Matrix Coefficients of the video used to derive luma and chroma values from red, green, and blue color primaries.
For clarity, the value and meanings for MatrixCoefficients are adopted from Table 4 of [@!ITU-H.273].</documentation>
    <restriction>
      <enum value="0" label="Identity"/>
      <enum value="1" label="ITU-R BT.709"/>
      <enum value="2" label="unspecified"/>
      <enum value="3" label="reserved"/>
      <enum value="4" label="US FCC 73.682"/>
      <enum value="5" label="ITU-R BT.470BG"/>
      <enum value="6" label="SMPTE 170M"/>
      <enum value="7" label="SMPTE 240M"/>
      <enum value="8" label="YCoCg"/>
      <enum value="9" label="BT2020 Non-constant Luminance"/>
      <enum value="10" label="BT2020 Constant Luminance"/>
      <enum value="11" label="SMPTE ST 2085"/>
      <enum value="12" label="Chroma-derived Non-constant Luminance"/>
      <enum value="13" label="Chroma-derived Constant Luminance"/>
      <enum value="14" label="ITU-R BT.2100-0"/>
    </restriction>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoColourMatrix"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="BitsPerChannel" path="\Segment\Tracks\TrackEntry\Video\Colour\BitsPerChannel" id="0x55B2" type="uinteger" minver="4" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Number of decoded bits per channel. A value of 0 indicates that the BitsPerChannel is unspecified.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoBitsPerChannel"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ChromaSubsamplingHorz" path="\Segment\Tracks\TrackEntry\Video\Colour\ChromaSubsamplingHorz" id="0x55B3" type="uinteger" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">The amount of pixels to remove in the Cr and Cb channels for every pixel not removed horizontally.
Example: For video with 4:2:0 chroma subsampling, the ChromaSubsamplingHorz **SHOULD** be set to 1.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoChromaSubsampHorz"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ChromaSubsamplingVert" path="\Segment\Tracks\TrackEntry\Video\Colour\ChromaSubsamplingVert" id="0x55B4" type="uinteger" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">The amount of pixels to remove in the Cr and Cb channels for every pixel not removed vertically.
Example: For video with 4:2:0 chroma subsampling, the ChromaSubsamplingVert **SHOULD** be set to 1.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoChromaSubsampVert"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="CbSubsamplingHorz" path="\Segment\Tracks\TrackEntry\Video\Colour\CbSubsamplingHorz" id="0x55B5" type="uinteger" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">The amount of pixels to remove in the Cb channel for every pixel not removed horizontally.
This is additive with ChromaSubsamplingHorz. Example: For video with 4:2:1 chroma subsampling,
the ChromaSubsamplingHorz **SHOULD** be set to 1 and CbSubsamplingHorz **SHOULD** be set to 1.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoCbSubsampHorz"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="CbSubsamplingVert" path="\Segment\Tracks\TrackEntry\Video\Colour\CbSubsamplingVert" id="0x55B6" type="uinteger" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">The amount of pixels to remove in the Cb channel for every pixel not removed vertically.
This is additive with ChromaSubsamplingVert.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoCbSubsampVert"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ChromaSitingHorz" path="\Segment\Tracks\TrackEntry\Video\Colour\ChromaSitingHorz" id="0x55B7" type="uinteger" minver="4" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">How chroma is subsampled horizontally.</documentation>
    <restriction>
      <enum value="0" label="unspecified"/>
      <enum value="1" label="left collocated"/>
      <enum value="2" label="half"/>
    </restriction>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoChromaSitHorz"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ChromaSitingVert" path="\Segment\Tracks\TrackEntry\Video\Colour\ChromaSitingVert" id="0x55B8" type="uinteger" minver="4" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">How chroma is subsampled vertically.</documentation>
    <restriction>
      <enum value="0" label="unspecified"/>
      <enum value="1" label="top collocated"/>
      <enum value="2" label="half"/>
    </restriction>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoChromaSitVert"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="Range" path="\Segment\Tracks\TrackEntry\Video\Colour\Range" id="0x55B9" type="uinteger" minver="4" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Clipping of the color ranges.</documentation>
    <restriction>
      <enum value="0" label="unspecified"/>
      <enum value="1" label="broadcast range"/>
      <enum value="2" label="full range (no clipping)"/>
      <enum value="3" label="defined by MatrixCoefficients / TransferCharacteristics"/>
    </restriction>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoColourRange"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="TransferCharacteristics" path="\Segment\Tracks\TrackEntry\Video\Colour\TransferCharacteristics" id="0x55BA" type="uinteger" minver="4" default="2" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The transfer characteristics of the video. For clarity,
the value and meanings for TransferCharacteristics are adopted from Table 3 of [@!ITU-H.273].</documentation>
    <restriction>
      <enum value="0" label="reserved"/>
      <enum value="1" label="ITU-R BT.709"/>
      <enum value="2" label="unspecified"/>
      <enum value="3" label="reserved2"/>
      <enum value="4" label="Gamma 2.2 curve - BT.470M"/>
      <enum value="5" label="Gamma 2.8 curve - BT.470BG"/>
      <enum value="6" label="SMPTE 170M"/>
      <enum value="7" label="SMPTE 240M"/>
      <enum value="8" label="Linear"/>
      <enum value="9" label="Log"/>
      <enum value="10" label="Log Sqrt"/>
      <enum value="11" label="IEC 61966-2-4"/>
      <enum value="12" label="ITU-R BT.1361 Extended Colour Gamut"/>
      <enum value="13" label="IEC 61966-2-1"/>
      <enum value="14" label="ITU-R BT.2020 10 bit"/>
      <enum value="15" label="ITU-R BT.2020 12 bit"/>
      <enum value="16" label="ITU-R BT.2100 Perceptual Quantization"/>
      <enum value="17" label="SMPTE ST 428-1"/>
      <enum value="18" label="ARIB STD-B67 (HLG)"/>
    </restriction>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoColourTransferCharacter"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="Primaries" path="\Segment\Tracks\TrackEntry\Video\Colour\Primaries" id="0x55BB" type="uinteger" minver="4" default="2" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The colour primaries of the video. For clarity,
the value and meanings for Primaries are adopted from Table 2 of [@!ITU-H.273].</documentation>
    <restriction>
      <enum value="0" label="reserved"/>
      <enum value="1" label="ITU-R BT.709"/>
      <enum value="2" label="unspecified"/>
      <enum value="3" label="reserved2"/>
      <enum value="4" label="ITU-R BT.470M"/>
      <enum value="5" label="ITU-R BT.470BG - BT.601 625"/>
      <enum value="6" label="ITU-R BT.601 525 - SMPTE 170M"/>
      <enum value="7" label="SMPTE 240M"/>
      <enum value="8" label="FILM"/>
      <enum value="9" label="ITU-R BT.2020"/>
      <enum value="10" label="SMPTE ST 428-1"/>
      <enum value="11" label="SMPTE RP 432-2"/>
      <enum value="12" label="SMPTE EG 432-2"/>
      <enum value="22" label="EBU Tech. 3213-E - JEDEC P22 phosphors"/>
    </restriction>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoColourPrimaries"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="MaxCLL" path="\Segment\Tracks\TrackEntry\Video\Colour\MaxCLL" id="0x55BC" type="uinteger" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">Maximum brightness of a single pixel (Maximum Content Light Level)
in candelas per square meter (cd/m^2^).</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoColourMaxCLL"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="MaxFALL" path="\Segment\Tracks\TrackEntry\Video\Colour\MaxFALL" id="0x55BD" type="uinteger" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">Maximum brightness of a single full frame (Maximum Frame-Average Light Level)
in candelas per square meter (cd/m^2^).</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoColourMaxFALL"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="MasteringMetadata" path="\Segment\Tracks\TrackEntry\Video\Colour\MasteringMetadata" id="0x55D0" type="master" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">SMPTE 2086 mastering data.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoColourMasterMeta"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="PrimaryRChromaticityX" path="\Segment\Tracks\TrackEntry\Video\Colour\MasteringMetadata\PrimaryRChromaticityX" id="0x55D1" type="float" minver="4" range="0x0p+0-0x1p+0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Red X chromaticity coordinate, as defined by [@!CIE-1931].</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoRChromaX"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="PrimaryRChromaticityY" path="\Segment\Tracks\TrackEntry\Video\Colour\MasteringMetadata\PrimaryRChromaticityY" id="0x55D2" type="float" minver="4" range="0x0p+0-0x1p+0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Red Y chromaticity coordinate, as defined by [@!CIE-1931].</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoRChromaY"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="PrimaryGChromaticityX" path="\Segment\Tracks\TrackEntry\Video\Colour\MasteringMetadata\PrimaryGChromaticityX" id="0x55D3" type="float" minver="4" range="0x0p+0-0x1p+0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Green X chromaticity coordinate, as defined by [@!CIE-1931].</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoGChromaX"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="PrimaryGChromaticityY" path="\Segment\Tracks\TrackEntry\Video\Colour\MasteringMetadata\PrimaryGChromaticityY" id="0x55D4" type="float" minver="4" range="0x0p+0-0x1p+0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Green Y chromaticity coordinate, as defined by [@!CIE-1931].</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoGChromaY"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="PrimaryBChromaticityX" path="\Segment\Tracks\TrackEntry\Video\Colour\MasteringMetadata\PrimaryBChromaticityX" id="0x55D5" type="float" minver="4" range="0x0p+0-0x1p+0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Blue X chromaticity coordinate, as defined by [@!CIE-1931].</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoBChromaX"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="PrimaryBChromaticityY" path="\Segment\Tracks\TrackEntry\Video\Colour\MasteringMetadata\PrimaryBChromaticityY" id="0x55D6" type="float" minver="4" range="0x0p+0-0x1p+0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Blue Y chromaticity coordinate, as defined by [@!CIE-1931].</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoBChromaY"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="WhitePointChromaticityX" path="\Segment\Tracks\TrackEntry\Video\Colour\MasteringMetadata\WhitePointChromaticityX" id="0x55D7" type="float" minver="4" range="0x0p+0-0x1p+0" maxOccurs="1">
    <documentation lang="en" purpose="definition">White X chromaticity coordinate, as defined by [@!CIE-1931].</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoWhitePointChromaX"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="WhitePointChromaticityY" path="\Segment\Tracks\TrackEntry\Video\Colour\MasteringMetadata\WhitePointChromaticityY" id="0x55D8" type="float" minver="4" range="0x0p+0-0x1p+0" maxOccurs="1">
    <documentation lang="en" purpose="definition">White Y chromaticity coordinate, as defined by [@!CIE-1931].</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoWhitePointChromaY"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="LuminanceMax" path="\Segment\Tracks\TrackEntry\Video\Colour\MasteringMetadata\LuminanceMax" id="0x55D9" type="float" minver="4" range="&gt;= 0x0p+0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Maximum luminance. Represented in candelas per square meter (cd/m^2^).</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoLuminanceMax"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="LuminanceMin" path="\Segment\Tracks\TrackEntry\Video\Colour\MasteringMetadata\LuminanceMin" id="0x55DA" type="float" minver="4" range="&gt;= 0x0p+0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Minimum luminance. Represented in candelas per square meter (cd/m^2^).</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoLuminanceMin"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="Projection" path="\Segment\Tracks\TrackEntry\Video\Projection" id="0x7670" type="master" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">Describes the video projection details. Used to render spherical, VR videos or flipping videos horizontally/vertically.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoProjection"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ProjectionType" path="\Segment\Tracks\TrackEntry\Video\Projection\ProjectionType" id="0x7671" type="uinteger" minver="4" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Describes the projection used for this video track.</documentation>
    <restriction>
      <enum value="0" label="rectangular"/>
      <enum value="1" label="equirectangular"/>
      <enum value="2" label="cubemap"/>
      <enum value="3" label="mesh"/>
    </restriction>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoProjectionType"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ProjectionPrivate" path="\Segment\Tracks\TrackEntry\Video\Projection\ProjectionPrivate" id="0x7672" type="binary" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">Private data that only applies to a specific projection.

*  If `ProjectionType` equals 0 (Rectangular),
     then this element **MUST NOT** be present.
*  If `ProjectionType` equals 1 (Equirectangular), then this element **MUST** be present and contain the same binary data that would be stored inside
      an ISOBMFF Equirectangular Projection Box ('equi').
*  If `ProjectionType` equals 2 (Cubemap), then this element **MUST** be present and contain the same binary data that would be stored
      inside an ISOBMFF Cubemap Projection Box ('cbmp').
*  If `ProjectionType` equals 3 (Mesh), then this element **MUST** be present and contain the same binary data that would be stored inside
       an ISOBMFF Mesh Projection Box ('mshp').</documentation>

<documentation lang="en" purpose="usage notes">ISOBMFF box size and fourcc fields are not included in the binary data,
but the FullBox version and flag fields are. This is to avoid
redundant framing information while preserving versioning and semantics between the two container formats.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoProjectionPrivate"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ProjectionPoseYaw" path="\Segment\Tracks\TrackEntry\Video\Projection\ProjectionPoseYaw" id="0x7673" type="float" range="&gt;= -0xB4p+0, &lt;= 0xB4p+0" minver="4" default="0x0p+0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Specifies a yaw rotation to the projection.

Value represents a clockwise rotation, in degrees, around the up vector. This rotation must be applied
before any `ProjectionPosePitch` or `ProjectionPoseRoll` rotations.
The value of this element **MUST** be in the -180 to 180 degree range, both included.

Setting `ProjectionPoseYaw` to 180 or -180 degrees, with the `ProjectionPoseRoll` and `ProjectionPosePitch` set to 0 degrees flips the image horizontally.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoProjectionPoseYaw"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ProjectionPosePitch" path="\Segment\Tracks\TrackEntry\Video\Projection\ProjectionPosePitch" id="0x7674" type="float" minver="4" range="&gt;= -0x5Ap+0, &lt;= 0x5Ap+0" default="0x0p+0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Specifies a pitch rotation to the projection.

Value represents a counter-clockwise rotation, in degrees, around the right vector. This rotation must be applied
after the `ProjectionPoseYaw` rotation and before the `ProjectionPoseRoll` rotation.
The value of this element **MUST** be in the -90 to 90 degree range, both included.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoProjectionPosePitch"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ProjectionPoseRoll" path="\Segment\Tracks\TrackEntry\Video\Projection\ProjectionPoseRoll" id="0x7675" type="float" minver="4" range="&gt;= -0xB4p+0, &lt;= 0xB4p+0" default="0x0p+0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Specifies a roll rotation to the projection.

Value represents a counter-clockwise rotation, in degrees, around the forward vector. This rotation must be applied
after the `ProjectionPoseYaw` and `ProjectionPosePitch` rotations.
The value of this element **MUST** be in the -180 to 180 degree range, both included.

Setting `ProjectionPoseRoll` to 180 or -180 degrees, the `ProjectionPoseYaw` to 180 or -180 degrees with `ProjectionPosePitch` set to 0 degrees flips the image vertically.

Setting `ProjectionPoseRoll` to 180 or -180 degrees, with the `ProjectionPoseYaw` and `ProjectionPosePitch` set to 0 degrees flips the image horizontally and vertically.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="VideoProjectionPoseRoll"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="Audio" path="\Segment\Tracks\TrackEntry\Audio" id="0xE1" type="master" maxOccurs="1">
    <documentation lang="en" purpose="definition">Audio settings.</documentation>
    <extension type="libmatroska" cppname="TrackAudio"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="SamplingFrequency" path="\Segment\Tracks\TrackEntry\Audio\SamplingFrequency" id="0xB5" type="float" range="&gt; 0x0p+0" default="0x1.f4p+12" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Sampling frequency in Hz.</documentation>
    <extension type="libmatroska" cppname="AudioSamplingFreq"/>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="OutputSamplingFrequency" path="\Segment\Tracks\TrackEntry\Audio\OutputSamplingFrequency" id="0x78B5" type="float" range="&gt; 0x0p+0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Real output sampling frequency in Hz (used for SBR techniques).</documentation>
    <implementation_note note_attribute="default">The default value for OutputSamplingFrequency of the same TrackEntry is equal to the SamplingFrequency.</implementation_note>
    <extension type="libmatroska" cppname="AudioOutputSamplingFreq"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="Channels" path="\Segment\Tracks\TrackEntry\Audio\Channels" id="0x9F" type="uinteger" range="not 0" default="1" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Numbers of channels in the track.</documentation>
    <extension type="libmatroska" cppname="AudioChannels"/>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="ChannelPositions" path="\Segment\Tracks\TrackEntry\Audio\ChannelPositions" id="0x7D7B" type="binary" minver="0" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Table of horizontal angles for each successive channel.</documentation>
    <extension type="libmatroska" cppname="AudioPosition"/>
  </element>
  <element name="BitDepth" path="\Segment\Tracks\TrackEntry\Audio\BitDepth" id="0x6264" type="uinteger" range="not 0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Bits per sample, mostly used for PCM.</documentation>
    <extension type="libmatroska" cppname="AudioBitDepth"/>
    <extension type="stream copy" keep="1"/>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="Emphasis" path="\Segment\Tracks\TrackEntry\Audio\Emphasis" id="0x52F1" type="uinteger" minver="5" default="0" minOccurs="1" maxOccurs="1" >
    <documentation lang="en" purpose="definition">Audio emphasis applied on audio samples. The player **MUST** apply the inverse emphasis to get the proper audio samples.</documentation>
    <restriction>
      <enum value="0" label="No emphasis"/>
      <enum value="1" label="CD audio">
        <documentation lang="en" purpose="definition">First order filter with zero point at 50 microseconds and a pole at 15 microseconds. Also found on DVD Audio and MPEG audio.</documentation>
      </enum>
      <enum value="2" label="reserved"/>
      <enum value="3" label="CCIT J.17">
        <documentation lang="en" purpose="definition">Defined in [@!ITU-J.17].</documentation>
      </enum>
      <enum value="4" label="FM 50">
        <documentation lang="en" purpose="definition">FM Radio in Europe. RC Filter with a time constant of 50 microseconds.</documentation>
      </enum>
      <enum value="5" label="FM 75">
        <documentation lang="en" purpose="definition">FM Radio in the USA. RC Filter with a time constant of 75 microseconds.</documentation>
      </enum>
      <enum value="10" label="Phono RIAA">
        <documentation lang="en" purpose="definition">Phono filter with time constants of t1=3180, t2=318 and t3=75 microseconds. [@!NAB1964]</documentation>
      </enum>
      <enum value="11" label="Phono IEC N78">
        <documentation lang="en" purpose="definition">Phono filter with time constants of t1=3180, t2=450 and t3=50 microseconds.</documentation>
      </enum>
      <enum value="12" label="Phono TELDEC">
        <documentation lang="en" purpose="definition">Phono filter with time constants of t1=3180, t2=318 and t3=50 microseconds.</documentation>
      </enum>
      <enum value="13" label="Phono EMI">
        <documentation lang="en" purpose="definition">Phono filter with time constants of t1=2500, t2=500 and t3=70 microseconds.</documentation>
      </enum>
      <enum value="14" label="Phono Columbia LP">
        <documentation lang="en" purpose="definition">Phono filter with time constants of t1=1590, t2=318 and t3=100 microseconds.</documentation>
      </enum>
      <enum value="15" label="Phono LONDON">
        <documentation lang="en" purpose="definition">Phono filter with time constants of t1=1590, t2=318 and t3=50 microseconds.</documentation>
      </enum>
      <enum value="16" label="Phono NARTB">
        <documentation lang="en" purpose="definition">Phono filter with time constants of t1=3180, t2=318 and t3=100 microseconds.</documentation>
      </enum>
    </restriction>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="TrackOperation" path="\Segment\Tracks\TrackEntry\TrackOperation" id="0xE2" type="master" minver="3" maxOccurs="1">
    <documentation lang="en" purpose="definition">Operation that needs to be applied on tracks to create this virtual track.
For more details look at (#track-operation).</documentation>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="TrackCombinePlanes" path="\Segment\Tracks\TrackEntry\TrackOperation\TrackCombinePlanes" id="0xE3" type="master" minver="3" maxOccurs="1">
    <documentation lang="en" purpose="definition">Contains the list of all video plane tracks that need to be combined to create this 3D track</documentation>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="TrackPlane" path="\Segment\Tracks\TrackEntry\TrackOperation\TrackCombinePlanes\TrackPlane" id="0xE4" type="master" minver="3" minOccurs="1">
    <documentation lang="en" purpose="definition">Contains a video plane track that need to be combined to create this 3D track</documentation>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="TrackPlaneUID" path="\Segment\Tracks\TrackEntry\TrackOperation\TrackCombinePlanes\TrackPlane\TrackPlaneUID" id="0xE5" type="uinteger" minver="3" range="not 0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The trackUID number of the track representing the plane.</documentation>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="TrackPlaneType" path="\Segment\Tracks\TrackEntry\TrackOperation\TrackCombinePlanes\TrackPlane\TrackPlaneType" id="0xE6" type="uinteger" minver="3" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The kind of plane this track corresponds to.</documentation>
    <restriction>
      <enum value="0" label="left eye"/>
      <enum value="1" label="right eye"/>
      <enum value="2" label="background"/>
    </restriction>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="TrackJoinBlocks" path="\Segment\Tracks\TrackEntry\TrackOperation\TrackJoinBlocks" id="0xE9" type="master" minver="3" maxOccurs="1">
    <documentation lang="en" purpose="definition">Contains the list of all tracks whose Blocks need to be combined to create this virtual track</documentation>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="TrackJoinUID" path="\Segment\Tracks\TrackEntry\TrackOperation\TrackJoinBlocks\TrackJoinUID" id="0xED" type="uinteger" minver="3" range="not 0" minOccurs="1">
    <documentation lang="en" purpose="definition">The trackUID number of a track whose blocks are used to create this virtual track.</documentation>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="TrickTrackUID" path="\Segment\Tracks\TrackEntry\TrickTrackUID" id="0xC0" type="uinteger" minver="0" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The TrackUID of the Smooth FF/RW video in the paired EBML structure corresponding to this video track. See [@?DivXTrickTrack].</documentation>
    <extension type="divx.com" divx="1"/>
  </element>
  <element name="TrickTrackSegmentUID" path="\Segment\Tracks\TrackEntry\TrickTrackSegmentUID" id="0xC1" type="binary" minver="0" maxver="0" length="16" maxOccurs="1">
    <documentation lang="en" purpose="definition">The SegmentUID of the Segment containing the track identified by TrickTrackUID. See [@?DivXTrickTrack].</documentation>
    <extension type="divx.com" divx="1"/>
  </element>
  <element name="TrickTrackFlag" path="\Segment\Tracks\TrackEntry\TrickTrackFlag" id="0xC6" type="uinteger" minver="0" maxver="0" default="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Set to 1 if this video track is a Smooth FF/RW track. If set to 1, MasterTrackUID and MasterTrackSegUID should be present and BlockGroups for this track must contain ReferenceFrame structures.
Otherwise, TrickTrackUID and TrickTrackSegUID must be present if this track has a corresponding Smooth FF/RW track. See [@?DivXTrickTrack].</documentation>
    <extension type="divx.com" divx="1"/>
  </element>
  <element name="TrickMasterTrackUID" path="\Segment\Tracks\TrackEntry\TrickMasterTrackUID" id="0xC7" type="uinteger" minver="0" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The TrackUID of the video track in the paired EBML structure that corresponds to this Smooth FF/RW track. See [@?DivXTrickTrack].</documentation>
    <extension type="divx.com" divx="1"/>
  </element>
  <element name="TrickMasterTrackSegmentUID" path="\Segment\Tracks\TrackEntry\TrickMasterTrackSegmentUID" id="0xC4" type="binary" minver="0" maxver="0" length="16" maxOccurs="1">
    <documentation lang="en" purpose="definition">The SegmentUID of the Segment containing the track identified by MasterTrackUID. See [@?DivXTrickTrack].</documentation>
    <extension type="divx.com" divx="1"/>
  </element>
  <element name="ContentEncodings" path="\Segment\Tracks\TrackEntry\ContentEncodings" id="0x6D80" type="master" maxOccurs="1">
    <documentation lang="en" purpose="definition">Settings for several content encoding mechanisms like compression or encryption.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ContentEncoding" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding" id="0x6240" type="master" minOccurs="1">
    <documentation lang="en" purpose="definition">Settings for one content encoding like compression or encryption.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ContentEncodingOrder" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding\ContentEncodingOrder" id="0x5031" type="uinteger" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Tell in which order to apply each `ContentEncoding` of the `ContentEncodings`.
The decoder/demuxer **MUST** start with the `ContentEncoding` with the highest `ContentEncodingOrder` and work its way down to the `ContentEncoding` with the lowest `ContentEncodingOrder`.
This value **MUST** be unique over for each `ContentEncoding` found in the `ContentEncodings` of this `TrackEntry`.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ContentEncodingScope" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding\ContentEncodingScope" id="0x5032" type="uinteger" default="1" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">A bit field that describes which Elements have been modified in this way.
Values (big-endian) can be OR'ed.</documentation>
    <restriction>
      <enum value="1" label="Block">
        <documentation lang="en" purpose="definition">All frame contents, excluding lacing data.</documentation>
      </enum>
      <enum value="2" label="Private">
        <documentation lang="en" purpose="definition">The track's `CodecPrivate` data.</documentation>
      </enum>
      <enum value="4" label="Next">
        <documentation lang="en" purpose="definition">The next ContentEncoding (next `ContentEncodingOrder`. Either the data inside `ContentCompression` and/or `ContentEncryption`).</documentation>
        <documentation lang="en" purpose="usage notes">This value **SHOULD NOT** be used as it's not supported by players.</documentation>
      </enum>
    </restriction>
    <extension type="webmproject.org" webm="1"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ContentEncodingType" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding\ContentEncodingType" id="0x5033" type="uinteger" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">A value describing what kind of transformation is applied.</documentation>
    <restriction>
      <enum value="0" label="Compression"/>
      <enum value="1" label="Encryption"/>
    </restriction>
    <extension type="webmproject.org" webm="1"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ContentCompression" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding\ContentCompression" id="0x5034" type="master" maxOccurs="1">
    <documentation lang="en" purpose="definition">Settings describing the compression used.
This Element **MUST** be present if the value of ContentEncodingType is 0 and absent otherwise.
Each block **MUST** be decompressable even if no previous block is available in order not to prevent seeking.</documentation>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ContentCompAlgo" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding\ContentCompression\ContentCompAlgo" id="0x4254" type="uinteger" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The compression algorithm used.</documentation>
    <documentation lang="en" purpose="usage notes">Compression method "1" (bzlib) and "2" (lzo1x) are lacking proper documentation on the format which limits implementation possibilities.
Due to licensing conflicts on commonly available libraries compression methods "2" (lzo1x) does not offer widespread interoperability.
A Matroska Writer **SHOULD NOT** use these compression methods by default.
A Matroska Reader **MAY** support methods "1" and "2" as possible, and **SHOULD** support other methods.</documentation>
    <restriction>
      <enum value="0" label="zlib">
        <documentation lang="en" purpose="definition">zlib compression [@!RFC1950].</documentation>
      </enum>
      <enum value="1" label="bzlib">
        <documentation lang="en" purpose="definition">bzip2 compression [@?BZIP2], **SHOULD NOT** be used; see usage notes.</documentation>
      </enum>
      <enum value="2" label="lzo1x">
        <documentation lang="en" purpose="definition">Lempel-Ziv-Oberhumer compression [@?LZO], **SHOULD NOT** be used; see usage notes.</documentation>
      </enum>
      <enum value="3" label="Header Stripping">
        <documentation lang="en" purpose="definition">Octets in `ContentCompSettings` ((#contentcompsettings-element)) have been stripped from each frame.</documentation>
      </enum>
    </restriction>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ContentCompSettings" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding\ContentCompression\ContentCompSettings" id="0x4255" type="binary" maxOccurs="1">
    <documentation lang="en" purpose="definition">Settings that might be needed by the decompressor. For Header Stripping (`ContentCompAlgo`=3),
the bytes that were removed from the beginning of each frames of the track.</documentation>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ContentEncryption" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding\ContentEncryption" id="0x5035" type="master" maxOccurs="1">
    <documentation lang="en" purpose="definition">Settings describing the encryption used.
This Element **MUST** be present if the value of `ContentEncodingType` is 1 (encryption) and **MUST** be ignored otherwise.
A Matroska Player **MAY** support encryption.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ContentEncAlgo" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding\ContentEncryption\ContentEncAlgo" id="0x47E1" type="uinteger" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The encryption algorithm used.</documentation>
    <restriction>
      <enum value="0" label="Not encrypted">
        <documentation lang="en" purpose="definition">The data are not encrypted.</documentation>
      </enum>
      <enum value="1" label="DES">
        <documentation lang="en" purpose="definition">Data Encryption Standard (DES) [@?FIPS.46-3].</documentation>
        <documentation lang="en" purpose="usage notes">This value **SHOULD** be avoided.</documentation>
      </enum>
      <enum value="2" label="3DES">
        <documentation lang="en" purpose="definition">Triple Data Encryption Algorithm [@?SP.800-67].</documentation>
        <documentation lang="en" purpose="usage notes">This value **SHOULD** be avoided.</documentation>
      </enum>
      <enum value="3" label="Twofish">
        <documentation lang="en" purpose="definition">Twofish Encryption Algorithm [@?Twofish].</documentation>
      </enum>
      <enum value="4" label="Blowfish">
        <documentation lang="en" purpose="definition">Blowfish Encryption Algorithm [@?Blowfish].</documentation>
        <documentation lang="en" purpose="usage notes">This value **SHOULD** be avoided.</documentation>
      </enum>
      <enum value="5" label="AES">
        <documentation lang="en" purpose="definition">Advanced Encryption Standard (AES) [@?FIPS.197].</documentation>
      </enum>
    </restriction>
    <extension type="webmproject.org" webm="1"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ContentEncKeyID" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding\ContentEncryption\ContentEncKeyID" id="0x47E2" type="binary" maxOccurs="1">
    <documentation lang="en" purpose="definition">For public key algorithms this is the ID of the public key the data was encrypted with.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ContentEncAESSettings" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding\ContentEncryption\ContentEncAESSettings" id="0x47E7" type="master" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">Settings describing the encryption algorithm used.</documentation>
    <implementation_note note_attribute="maxOccurs">ContentEncAESSettings **MUST NOT** be set (maxOccurs=0) if ContentEncAlgo is not AES (5).</implementation_note>
    <extension type="webmproject.org" webm="1"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="AESSettingsCipherMode" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding\ContentEncryption\ContentEncAESSettings\AESSettingsCipherMode" id="0x47E8" type="uinteger" minver="4" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The AES cipher mode used in the encryption.</documentation>
    <implementation_note note_attribute="maxOccurs">AESSettingsCipherMode **MUST NOT** be set (maxOccurs=0) if ContentEncAlgo is not AES (5).</implementation_note>
    <restriction>
      <enum value="1" label="AES-CTR">
        <documentation lang="en" purpose="definition">Counter [@?SP.800-38A].</documentation>
      </enum>
      <enum value="2" label="AES-CBC">
        <documentation lang="en" purpose="definition">Cipher Block Chaining [@?SP.800-38A].</documentation>
      </enum>
    </restriction>
    <extension type="webmproject.org" webm="1"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ContentSignature" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding\ContentEncryption\ContentSignature" id="0x47E3" type="binary" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">A cryptographic signature of the contents.</documentation>
  </element>
  <element name="ContentSigKeyID" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding\ContentEncryption\ContentSigKeyID" id="0x47E4" type="binary" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">This is the ID of the private key the data was signed with.</documentation>
  </element>
  <element name="ContentSigAlgo" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding\ContentEncryption\ContentSigAlgo" id="0x47E5" type="uinteger" maxver="0" default="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The algorithm used for the signature.</documentation>
    <restriction>
      <enum value="0" label="Not signed"/>
      <enum value="1" label="RSA"/>
    </restriction>
  </element>
  <element name="ContentSigHashAlgo" path="\Segment\Tracks\TrackEntry\ContentEncodings\ContentEncoding\ContentEncryption\ContentSigHashAlgo" id="0x47E6" type="uinteger" maxver="0" default="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The hash algorithm used for the signature.</documentation>
    <restriction>
      <enum value="0" label="Not signed"/>
      <enum value="1" label="SHA1-160"/>
      <enum value="2" label="MD5"/>
    </restriction>
  </element>
  <element name="Cues" path="\Segment\Cues" id="0x1C53BB6B" type="master" maxOccurs="1">
    <documentation lang="en" purpose="definition">A Top-Level Element to speed seeking access.
All entries are local to the Segment.</documentation>
    <implementation_note note_attribute="minOccurs">This Element **SHOULD** be set when the Segment is not transmitted as a live stream; see (#livestreaming).</implementation_note>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="CuePoint" path="\Segment\Cues\CuePoint" id="0xBB" type="master" minOccurs="1">
    <documentation lang="en" purpose="definition">Contains all information relative to a seek point in the Segment.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="CueTime" path="\Segment\Cues\CuePoint\CueTime" id="0xB3" type="uinteger" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Absolute timestamp of the seek point, expressed in Matroska Ticks -- i.e., in nanoseconds; see (#timestamp-ticks).</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="CueTrackPositions" path="\Segment\Cues\CuePoint\CueTrackPositions" id="0xB7" type="master" minOccurs="1">
    <documentation lang="en" purpose="definition">Contain positions for different tracks corresponding to the timestamp.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="CueTrack" path="\Segment\Cues\CuePoint\CueTrackPositions\CueTrack" id="0xF7" type="uinteger" range="not 0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The track for which a position is given.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="CueClusterPosition" path="\Segment\Cues\CuePoint\CueTrackPositions\CueClusterPosition" id="0xF1" type="uinteger" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The Segment Position ((#segment-position)) of the Cluster containing the associated Block.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="CueRelativePosition" path="\Segment\Cues\CuePoint\CueTrackPositions\CueRelativePosition" id="0xF0" type="uinteger" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">The relative position inside the Cluster of the referenced SimpleBlock or BlockGroup
with 0 being the first possible position for an Element inside that Cluster.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="CueDuration" path="\Segment\Cues\CuePoint\CueTrackPositions\CueDuration" id="0xB2" type="uinteger" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">The duration of the block, expressed in Segment Ticks which is based on TimestampScale; see (#timestamp-ticks).
If missing, the track's DefaultDuration does not apply and no duration information is available in terms of the cues.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="CueBlockNumber" path="\Segment\Cues\CuePoint\CueTrackPositions\CueBlockNumber" id="0x5378" type="uinteger" range="not 0" maxOccurs="1">
    <documentation lang="en" purpose="definition">Number of the Block in the specified Cluster.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="CueCodecState" path="\Segment\Cues\CuePoint\CueTrackPositions\CueCodecState" id="0xEA" type="uinteger" minver="2" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The Segment Position ((#segment-position)) of the Codec State corresponding to this Cue Element.
0 means that the data is taken from the initial Track Entry.</documentation>
  </element>
  <element name="CueReference" path="\Segment\Cues\CuePoint\CueTrackPositions\CueReference" id="0xDB" type="master" minver="2">
    <documentation lang="en" purpose="definition">The Clusters containing the referenced Blocks.</documentation>
  </element>
  <element name="CueRefTime" path="\Segment\Cues\CuePoint\CueTrackPositions\CueReference\CueRefTime" id="0x96" type="uinteger" minver="2" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Timestamp of the referenced Block, expressed in Matroska Ticks -- i.e., in nanoseconds; see (#timestamp-ticks).</documentation>
  </element>
  <element name="CueRefCluster" path="\Segment\Cues\CuePoint\CueTrackPositions\CueReference\CueRefCluster" id="0x97" type="uinteger" minver="0" maxver="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The Segment Position of the Cluster containing the referenced Block.</documentation>
  </element>
  <element name="CueRefNumber" path="\Segment\Cues\CuePoint\CueTrackPositions\CueReference\CueRefNumber" id="0x535F" type="uinteger" minver="0" maxver="0" range="not 0" default="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Number of the referenced Block of Track X in the specified Cluster.</documentation>
  </element>
  <element name="CueRefCodecState" path="\Segment\Cues\CuePoint\CueTrackPositions\CueReference\CueRefCodecState" id="0xEB" type="uinteger" minver="0" maxver="0" default="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The Segment Position of the Codec State corresponding to this referenced Element.
0 means that the data is taken from the initial Track Entry.</documentation>
  </element>
  <element name="Attachments" path="\Segment\Attachments" id="0x1941A469" type="master" maxOccurs="1">
    <documentation lang="en" purpose="definition">Contain attached files.</documentation>
  </element>
  <element name="AttachedFile" path="\Segment\Attachments\AttachedFile" id="0x61A7" type="master" minOccurs="1">
    <documentation lang="en" purpose="definition">An attached file.</documentation>
    <extension type="libmatroska" cppname="Attached"/>
  </element>
  <element name="FileDescription" path="\Segment\Attachments\AttachedFile\FileDescription" id="0x467E" type="utf-8" maxOccurs="1">
    <documentation lang="en" purpose="definition">A human-friendly name for the attached file.</documentation>
  </element>
  <element name="FileName" path="\Segment\Attachments\AttachedFile\FileName" id="0x466E" type="utf-8" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Filename of the attached file.</documentation>
  </element>
  <element name="FileMediaType" path="\Segment\Attachments\AttachedFile\FileMediaType" id="0x4660" type="string" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Media type of the file following the [@!RFC6838] format.</documentation>
    <extension type="libmatroska" cppname="MimeType"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="FileData" path="\Segment\Attachments\AttachedFile\FileData" id="0x465C" type="binary" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The data of the file.</documentation>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="FileUID" path="\Segment\Attachments\AttachedFile\FileUID" id="0x46AE" type="uinteger" range="not 0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Unique ID representing the file, as random as possible.</documentation>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="FileReferral" path="\Segment\Attachments\AttachedFile\FileReferral" id="0x4675" type="binary" minver="0" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">A binary value that a track/codec can refer to when the attachment is needed.</documentation>
  </element>
  <element name="FileUsedStartTime" path="\Segment\Attachments\AttachedFile\FileUsedStartTime" id="0x4661" type="uinteger" minver="0" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The timestamp at which this optimized font attachment comes into context, expressed in Segment Ticks which is based on TimestampScale. See [@?DivXWorldFonts].</documentation>
    <documentation lang="en" purpose="usage notes">This element is reserved for future use and if written **MUST** be the segment start timestamp.</documentation>
    <extension type="divx.com" divx="1"/>
  </element>
  <element name="FileUsedEndTime" path="\Segment\Attachments\AttachedFile\FileUsedEndTime" id="0x4662" type="uinteger" minver="0" maxver="0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The timestamp at which this optimized font attachment goes out of context, expressed in Segment Ticks which is based on TimestampScale. See [@?DivXWorldFonts].</documentation>
    <documentation lang="en" purpose="usage notes">This element is reserved for future use and if written **MUST** be the segment end timestamp.</documentation>
    <extension type="divx.com" divx="1"/>
  </element>
  <element name="Chapters" path="\Segment\Chapters" id="0x1043A770" type="master" maxOccurs="1" recurring="1">
    <documentation lang="en" purpose="definition">A system to define basic menus and partition data.
For more detailed information, look at the Chapters explanation in (#chapters).</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="EditionEntry" path="\Segment\Chapters\EditionEntry" id="0x45B9" type="master" minOccurs="1">
    <documentation lang="en" purpose="definition">Contains all information about a Segment edition.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="EditionUID" path="\Segment\Chapters\EditionEntry\EditionUID" id="0x45BC" type="uinteger" range="not 0" maxOccurs="1">
    <documentation lang="en" purpose="definition">A unique ID to identify the edition. It's useful for tagging an edition.</documentation>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="EditionFlagHidden" path="\Segment\Chapters\EditionEntry\EditionFlagHidden" id="0x45BD" type="uinteger" range="0-1" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Set to 1 if an edition is hidden. Hidden editions **SHOULD NOT** be available to the user interface
(but still to Control Tracks; see (#chapter-flags) on Chapter flags).</documentation>
    <extension type="other document" spec="control-track"/>
  </element>
  <element name="EditionFlagDefault" path="\Segment\Chapters\EditionEntry\EditionFlagDefault" id="0x45DB" type="uinteger" range="0-1" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Set to 1 if the edition **SHOULD** be used as the default one.</documentation>
  </element>
  <element name="EditionFlagOrdered" path="\Segment\Chapters\EditionEntry\EditionFlagOrdered" id="0x45DD" type="uinteger" range="0-1" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Set to 1 if the chapters can be defined multiple times and the order to play them is enforced; see (#editionflagordered).</documentation>
  </element>
  <element name="EditionDisplay" path="\Segment\Chapters\EditionEntry\EditionDisplay" id="0x4520" type="master" minver="5">
    <documentation lang="en" purpose="definition">Contains a possible string to use for the edition display for the given languages.</documentation>
  </element>
  <element name="EditionString" path="\Segment\Chapters\EditionEntry\EditionDisplay\EditionString" id="0x4521" type="utf-8" minver="5" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Contains the string to use as the edition name.</documentation>
  </element>
  <element name="EditionLanguageIETF" path="\Segment\Chapters\EditionEntry\EditionDisplay\EditionLanguageIETF" id="0x45E4" type="string" minver="5">
    <documentation lang="en" purpose="definition">One language corresponding to the EditionString,
in the [@!BCP47] form; see (#language-codes) on language codes.</documentation>
  </element>
  <element name="ChapterAtom" path="\Segment\Chapters\EditionEntry\+ChapterAtom" id="0xB6" type="master" minOccurs="1" recursive="1">
    <documentation lang="en" purpose="definition">Contains the atom information to use as the chapter atom (apply to all tracks).</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="ChapterUID" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterUID" id="0x73C4" type="uinteger" range="not 0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">A unique ID to identify the Chapter.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="stream copy" keep="1"/>
  </element>
  <element name="ChapterStringUID" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterStringUID" id="0x5654" type="utf-8" minver="3" maxOccurs="1">
    <documentation lang="en" purpose="definition">A unique string ID to identify the Chapter.
For example it is used as the storage for [@?WebVTT] cue identifier values.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="ChapterTimeStart" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterTimeStart" id="0x91" type="uinteger" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Timestamp of the start of Chapter, expressed in Matroska Ticks -- i.e., in nanoseconds; see (#timestamp-ticks).</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="ChapterTimeEnd" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterTimeEnd" id="0x92" type="uinteger" maxOccurs="1">
    <documentation lang="en" purpose="definition">Timestamp of the end of Chapter timestamp excluded, expressed in Matroska Ticks -- i.e., in nanoseconds; see (#timestamp-ticks).
The value **MUST** be greater than or equal to the `ChapterTimeStart` of the same `ChapterAtom`.</documentation>
    <documentation lang="en" purpose="usage notes">The `ChapterTimeEnd` timestamp value being excluded, it **MUST** take in account the duration of
the last frame it includes, especially for the `ChapterAtom` using the last frames of the `Segment`.</documentation>
    <implementation_note note_attribute="minOccurs">ChapterTimeEnd **MUST** be set (minOccurs=1) if the Edition is an ordered edition; see (#editionflagordered), unless it's a `Parent Chapter`; see (#nested-chapters)</implementation_note>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="ChapterFlagHidden" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterFlagHidden" id="0x98" type="uinteger" range="0-1" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Set to 1 if a chapter is hidden. Hidden chapters **SHOULD NOT** be available to the user interface
(but still to Control Tracks; see (#chapterflaghidden) on Chapter flags).</documentation>
  </element>
  <element name="ChapterFlagEnabled" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterFlagEnabled" id="0x4598" type="uinteger" range="0-1" default="1" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Set to 1 if the chapter is enabled. It can be enabled/disabled by a Control Track.
When disabled, the movie **SHOULD** skip all the content between the TimeStart and TimeEnd of this chapter; see (#chapter-flags) on Chapter flags.</documentation>
    <extension type="other document" spec="control-track"/>
  </element>
  <element name="ChapterSegmentUUID" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterSegmentUUID" id="0x6E67" type="binary" length="16" maxOccurs="1">
    <documentation lang="en" purpose="definition">The SegmentUUID of another Segment to play during this chapter.</documentation>
    <documentation lang="en" purpose="usage notes">The value **MUST NOT** be the `SegmentUUID` value of the `Segment` it belongs to.</documentation>
    <implementation_note note_attribute="minOccurs">ChapterSegmentUUID **MUST** be set (minOccurs=1) if ChapterSegmentEditionUID is used; see (#medium-linking) on medium-linking Segments.</implementation_note>
    <extension type="libmatroska" cppname="ChapterSegmentUID"/>
  </element>
  <element name="ChapterSkipType" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterSkipType" id="0x4588" type="uinteger" maxOccurs="1" minver="5">
    <documentation lang="en" purpose="definition">Indicate what type of content the ChapterAtom contains and might be skipped. It can be used to automatically skip content based on the type.
If a `ChapterAtom` is inside a `ChapterAtom` that has a `ChapterSkipType` set, it **MUST NOT** have a `ChapterSkipType` or have a `ChapterSkipType` with the same value as it's parent `ChapterAtom`.
If the `ChapterAtom` doesn't contain a `ChapterTimeEnd`, the value of the `ChapterSkipType` is only valid until the next `ChapterAtom` with a `ChapterSkipType` value or the end of the file.
    </documentation>
    <extension type="webmproject.org" webm="0"/>
    <restriction>
      <enum value="0" label="No Skipping">
        <documentation lang="en" purpose="definition">Content which should not be skipped.</documentation>
      </enum>
      <enum value="1" label="Opening Credits">
        <documentation lang="en" purpose="definition">Credits usually found at the beginning of the content.</documentation>
      </enum>
      <enum value="2" label="End Credits">
        <documentation lang="en" purpose="definition">Credits usually found at the end of the content.</documentation>
      </enum>
      <enum value="3" label="Recap">
        <documentation lang="en" purpose="definition">Recap of previous episodes of the content, usually found around the beginning.</documentation>
      </enum>
      <enum value="4" label="Next Preview">
        <documentation lang="en" purpose="definition">Preview of the next episode of the content, usually found around the end. It may contain spoilers the user wants to avoid.</documentation>
      </enum>
      <enum value="5" label="Preview">
        <documentation lang="en" purpose="definition">Preview of the current episode of the content, usually found around the beginning. It may contain spoilers the user want to avoid.</documentation>
      </enum>
      <enum value="6" label="Advertisement">
        <documentation lang="en" purpose="definition">Advertisement within the content.</documentation>
      </enum>
    </restriction>
  </element>
  <element name="ChapterSegmentEditionUID" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterSegmentEditionUID" id="0x6EBC" type="uinteger" range="not 0" maxOccurs="1">
    <documentation lang="en" purpose="definition">The EditionUID to play from the Segment linked in ChapterSegmentUUID.
If ChapterSegmentEditionUID is undeclared, then no Edition of the linked Segment is used; see (#medium-linking) on medium-linking Segments.</documentation>
  </element>
  <element name="ChapterPhysicalEquiv" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterPhysicalEquiv" id="0x63C3" type="uinteger" maxOccurs="1">
    <documentation lang="en" purpose="definition">Specify the physical equivalent of this ChapterAtom like "DVD" (60) or "SIDE" (50);
see (#physical-types) for a complete list of values.</documentation>
  </element>
  <element name="ChapterTrack" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterTrack" id="0x8F" type="master" maxOccurs="1">
    <documentation lang="en" purpose="definition">List of tracks on which the chapter applies. If this Element is not present, all tracks apply</documentation>
    <extension type="other document" spec="control-track"/>
  </element>
  <element name="ChapterTrackUID" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterTrack\ChapterTrackUID" id="0x89" type="uinteger" range="not 0" minOccurs="1">
    <documentation lang="en" purpose="definition">UID of the Track to apply this chapter to.
In the absence of a control track, choosing this chapter will select the listed Tracks and deselect unlisted tracks.
Absence of this Element indicates that the Chapter **SHOULD** be applied to any currently used Tracks.</documentation>
    <extension type="libmatroska" cppname="ChapterTrackNumber"/>
    <extension type="other document" spec="control-track"/>
  </element>
  <element name="ChapterDisplay" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterDisplay" id="0x80" type="master">
    <documentation lang="en" purpose="definition">Contains all possible strings to use for the chapter display.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="ChapString" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterDisplay\ChapString" id="0x85" type="utf-8" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Contains the string to use as the chapter atom.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="ChapterString"/>
  </element>
  <element name="ChapLanguage" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterDisplay\ChapLanguage" id="0x437C" type="string" default="eng" minOccurs="1">
    <documentation lang="en" purpose="definition">A language corresponding to the string,
in the Matroska languages form; see (#language-codes) on language codes.
This Element **MUST** be ignored if a ChapLanguageBCP47 Element is used within the same ChapterDisplay Element.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="ChapterLanguage"/>
  </element>
  <element name="ChapLanguageBCP47" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterDisplay\ChapLanguageBCP47" id="0x437D" type="string" minver="4">
    <documentation lang="en" purpose="definition">A language corresponding to the ChapString,
in the [@!BCP47] form; see (#language-codes) on language codes.
If a ChapLanguageBCP47 Element is used, then any ChapLanguage and ChapCountry Elements used in the same ChapterDisplay **MUST** be ignored.</documentation>
    <extension type="libmatroska" cppname="ChapLanguageIETF"/>
  </element>
  <element name="ChapCountry" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapterDisplay\ChapCountry" id="0x437E" type="string">
    <documentation lang="en" purpose="definition">A country corresponding to the string,
in the Matroska countries form; see (#country-codes) on country codes.
This Element **MUST** be ignored if a ChapLanguageBCP47 Element is used within the same ChapterDisplay Element.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="ChapterCountry"/>
  </element>
  <element name="ChapProcess" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapProcess" id="0x6944" type="master">
    <documentation lang="en" purpose="definition">Contains all the commands associated to the Atom.</documentation>
    <extension type="libmatroska" cppname="ChapterProcess"/>
  </element>
  <element name="ChapProcessCodecID" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapProcess\ChapProcessCodecID" id="0x6955" type="uinteger" default="0" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Contains the type of the codec used for the processing.
A value of 0 means built-in Matroska processing (to be defined), a value of 1 means the DVD command set is used; see (#menu-features) on DVD menus.
More codec IDs can be added later.</documentation>
    <extension type="libmatroska" cppname="ChapterProcessCodecID"/>
  </element>
  <element name="ChapProcessPrivate" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapProcess\ChapProcessPrivate" id="0x450D" type="binary" maxOccurs="1">
    <documentation lang="en" purpose="definition">Some optional data attached to the ChapProcessCodecID information.
    For ChapProcessCodecID = 1, it is the "DVD level" equivalent; see (#menu-features) on DVD menus.</documentation>
    <extension type="libmatroska" cppname="ChapterProcessPrivate"/>
  </element>
  <element name="ChapProcessCommand" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapProcess\ChapProcessCommand" id="0x6911" type="master">
    <documentation lang="en" purpose="definition">Contains all the commands associated to the Atom.</documentation>
    <extension type="libmatroska" cppname="ChapterProcessCommand"/>
  </element>
  <element name="ChapProcessTime" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapProcess\ChapProcessCommand\ChapProcessTime" id="0x6922" type="uinteger" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Defines when the process command **SHOULD** be handled</documentation>
    <restriction>
      <enum value="0" label="during the whole chapter"/>
      <enum value="1" label="before starting playback"/>
      <enum value="2" label="after playback of the chapter"/>
    </restriction>
    <extension type="libmatroska" cppname="ChapterProcessTime"/>
  </element>
  <element name="ChapProcessData" path="\Segment\Chapters\EditionEntry\+ChapterAtom\ChapProcess\ChapProcessCommand\ChapProcessData" id="0x6933" type="binary" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Contains the command information.
The data **SHOULD** be interpreted depending on the ChapProcessCodecID value. For ChapProcessCodecID = 1,
the data correspond to the binary DVD cell pre/post commands; see (#menu-features) on DVD menus.</documentation>
    <extension type="libmatroska" cppname="ChapterProcessData"/>
  </element>
  <element name="Tags" path="\Segment\Tags" id="0x1254C367" type="master">
    <documentation lang="en" purpose="definition">Element containing metadata describing Tracks, Editions, Chapters, Attachments, or the Segment as a whole.
A list of valid tags can be found in [@?MatroskaTags].</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="Tag" path="\Segment\Tags\Tag" id="0x7373" type="master" minOccurs="1">
    <documentation lang="en" purpose="definition">A single metadata descriptor.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="Targets" path="\Segment\Tags\Tag\Targets" id="0x63C0" type="master" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Specifies which other elements the metadata represented by the Tag applies to.
If empty or omitted, then the Tag describes everything in the Segment.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="TagTargets"/>
  </element>
  <element name="TargetTypeValue" path="\Segment\Tags\Tag\Targets\TargetTypeValue" id="0x68CA" type="uinteger" default="50" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">A number to indicate the logical level of the target.</documentation>
    <restriction>
      <enum value="70" label="COLLECTION">
        <documentation lang="en" purpose="definition">The highest hierarchical level that tags can describe.</documentation>
      </enum>
      <enum value="60" label="EDITION / ISSUE / VOLUME / OPUS / SEASON / SEQUEL">
        <documentation lang="en" purpose="definition">A list of lower levels grouped together.</documentation>
      </enum>
      <enum value="50" label="ALBUM / OPERA / CONCERT / MOVIE / EPISODE">
        <documentation lang="en" purpose="definition">The most common grouping level of music and video (equals to an episode for TV series).</documentation>
      </enum>
      <enum value="40" label="PART / SESSION">
        <documentation lang="en" purpose="definition">When an album or episode has different logical parts.</documentation>
      </enum>
      <enum value="30" label="TRACK / SONG / CHAPTER">
        <documentation lang="en" purpose="definition">The common parts of an album or movie.</documentation>
      </enum>
      <enum value="20" label="SUBTRACK / MOVEMENT / SCENE">
        <documentation lang="en" purpose="definition">Corresponds to parts of a track for audio like a movement, or a scene in a movie.</documentation>
      </enum>
      <enum value="10" label="SHOT">
        <documentation lang="en" purpose="definition">The lowest hierarchy found in music or movies.</documentation>
      </enum>
    </restriction>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="TagTargetTypeValue"/>
  </element>
  <element name="TargetType" path="\Segment\Tags\Tag\Targets\TargetType" id="0x63CA" type="string" maxOccurs="1">
    <documentation lang="en" purpose="definition">An informational string that can be used to display the logical level of the target like "ALBUM", "TRACK", "MOVIE", "CHAPTER", etc.</documentation>
    <restriction>
      <enum value="COLLECTION" label="TargetTypeValue 70"/>
      <enum value="EDITION" label="TargetTypeValue 60"/>
      <enum value="ISSUE" label="TargetTypeValue 60"/>
      <enum value="VOLUME" label="TargetTypeValue 60"/>
      <enum value="OPUS" label="TargetTypeValue 60"/>
      <enum value="SEASON" label="TargetTypeValue 60"/>
      <enum value="SEQUEL" label="TargetTypeValue 60"/>
      <enum value="ALBUM" label="TargetTypeValue 50"/>
      <enum value="OPERA" label="TargetTypeValue 50"/>
      <enum value="CONCERT" label="TargetTypeValue 50"/>
      <enum value="MOVIE" label="TargetTypeValue 50"/>
      <enum value="EPISODE" label="TargetTypeValue 50"/>
      <enum value="PART" label="TargetTypeValue 40"/>
      <enum value="SESSION" label="TargetTypeValue 40"/>
      <enum value="TRACK" label="TargetTypeValue 30"/>
      <enum value="SONG" label="TargetTypeValue 30"/>
      <enum value="CHAPTER" label="TargetTypeValue 30"/>
      <enum value="SUBTRACK" label="TargetTypeValue 20"/>
      <enum value="MOVEMENT" label="TargetTypeValue 20"/>
      <enum value="SCENE" label="TargetTypeValue 20"/>
      <enum value="SHOT" label="TargetTypeValue 10"/>
    </restriction>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="TagTargetType"/>
  </element>
  <element name="TagTrackUID" path="\Segment\Tags\Tag\Targets\TagTrackUID" id="0x63C5" type="uinteger" default="0">
    <documentation lang="en" purpose="definition">A unique ID to identify the Track(s) the tags belong to.</documentation>
    <documentation lang="en" purpose="usage notes">If the value is 0 at this level, the tags apply to all tracks in the Segment.
If set to any other value, it **MUST** match the `TrackUID` value of a track found in this Segment.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="TagEditionUID" path="\Segment\Tags\Tag\Targets\TagEditionUID" id="0x63C9" type="uinteger" default="0">
    <documentation lang="en" purpose="definition">A unique ID to identify the EditionEntry(s) the tags belong to.</documentation>
    <documentation lang="en" purpose="usage notes">If the value is 0 at this level, the tags apply to all editions in the Segment.
If set to any other value, it **MUST** match the `EditionUID` value of an edition found in this Segment.</documentation>
  </element>
  <element name="TagChapterUID" path="\Segment\Tags\Tag\Targets\TagChapterUID" id="0x63C4" type="uinteger" default="0">
    <documentation lang="en" purpose="definition">A unique ID to identify the Chapter(s) the tags belong to.</documentation>
    <documentation lang="en" purpose="usage notes">If the value is 0 at this level, the tags apply to all chapters in the Segment.
If set to any other value, it **MUST** match the `ChapterUID` value of a chapter found in this Segment.</documentation>
  </element>
  <element name="TagAttachmentUID" path="\Segment\Tags\Tag\Targets\TagAttachmentUID" id="0x63C6" type="uinteger" default="0">
    <documentation lang="en" purpose="definition">A unique ID to identify the Attachment(s) the tags belong to.</documentation>
    <documentation lang="en" purpose="usage notes">If the value is 0 at this level, the tags apply to all the attachments in the Segment.
If set to any other value, it **MUST** match the `FileUID` value of an attachment found in this Segment.</documentation>
  </element>
  <element name="SimpleTag" path="\Segment\Tags\Tag\+SimpleTag" id="0x67C8" type="master" minOccurs="1" recursive="1">
    <documentation lang="en" purpose="definition">Contains general information about the target.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="TagSimple"/>
  </element>
  <element name="TagName" path="\Segment\Tags\Tag\+SimpleTag\TagName" id="0x45A3" type="utf-8" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">The name of the Tag that is going to be stored.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="TagLanguage" path="\Segment\Tags\Tag\+SimpleTag\TagLanguage" id="0x447A" type="string" default="und" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">Specifies the language of the tag specified,
in the Matroska languages form; see (#language-codes) on language codes.
This Element **MUST** be ignored if the TagLanguageBCP47 Element is used within the same SimpleTag Element.</documentation>
    <extension type="webmproject.org" webm="1"/>
    <extension type="libmatroska" cppname="TagLangue"/>
  </element>
  <element name="TagLanguageBCP47" path="\Segment\Tags\Tag\+SimpleTag\TagLanguageBCP47" id="0x447B" type="string" minver="4" maxOccurs="1">
    <documentation lang="en" purpose="definition">The language used in the TagString,
in the [@!BCP47] form; see (#language-codes) on language codes.
If this Element is used, then any TagLanguage Elements used in the same SimpleTag **MUST** be ignored.</documentation>
    <extension type="libmatroska" cppname="TagLanguageIETF"/>
  </element>
  <element name="TagDefault" path="\Segment\Tags\Tag\+SimpleTag\TagDefault" id="0x4484" type="uinteger" range="0-1" default="1" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">A boolean value to indicate if this is the default/original language to use for the given tag.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="TagDefaultBogus" path="\Segment\Tags\Tag\+SimpleTag\TagDefaultBogus" id="0x44B4" type="uinteger" minver="0" maxver="0" range="0-1" default="1" minOccurs="1" maxOccurs="1">
    <documentation lang="en" purpose="definition">A variant of the TagDefault element with a bogus Element ID; see (#tagdefault-element).</documentation>
  </element>
  <element name="TagString" path="\Segment\Tags\Tag\+SimpleTag\TagString" id="0x4487" type="utf-8" maxOccurs="1">
    <documentation lang="en" purpose="definition">The value of the Tag.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
  <element name="TagBinary" path="\Segment\Tags\Tag\+SimpleTag\TagBinary" id="0x4485" type="binary" maxOccurs="1">
    <documentation lang="en" purpose="definition">The values of the Tag, if it is binary. Note that this cannot be used in the same SimpleTag as TagString.</documentation>
    <extension type="webmproject.org" webm="1"/>
  </element>
</EBMLSchema>''';
