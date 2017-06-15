# ***** BEGIN LICENSE BLOCK *****
# Version: MPL 1.1
#
# The contents of this file are subject to the Mozilla Public License Version
# 1.1 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
# for the specific language governing rights and limitations under the
# License.
#
# The Original Code is IRC Auto Downloader
#
# The Initial Developer of the Original Code is
# David Nilsson.
# Portions created by the Initial Developer are Copyright (C) 2010, 2011
# the Initial Developer. All Rights Reserved.
#
# Contributor(s):
#
# ***** END LICENSE BLOCK *****

#
# Some constants used by other modules.
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::Constants;

use constant {
	UPLOAD_WATCH_FOLDER	=> 'watchdir',
	UPLOAD_WEBUI		=> 'webui',
	UPLOAD_FTP			=> 'ftp',
	UPLOAD_TOOL			=> 'exec',
	UPLOAD_DYNDIR		=> 'dyndir',
	UPLOAD_RTORRENT		=> 'rtorrent',
};

our $tvResolutions = [
	["Portable Device", "PD"],
	["SD", "SDTV", "Standard Def", "Standard Definition"],
	["480i"],
	["480p"],
	["576p"],
	["720p"],
	["810p"],
	["1080i"],
	["1080p"],
];

our $tvSources = [
	["DSR"],
	["PDTV"],
	["HDTV"],
	["HR.PDTV"],
	["HR.HDTV"],
	["DVDRip"],
	["DVDSCR", "DVDScr", "DVDSCREENER", "DVDScreener", "DVD-SCREENER", "DVD-Screener", "SCR", "Scr", "SCREENER", "Screener"],
	["BDr"],
	["BD5"],
	["BD9"],
	["BDRip"],
	["BRRip", "BLURAYRiP"],
	["DVDR", "MDVDR", "DVD", "DVD-R"],
	["HDDVD", "HD-DVD"],
	["HDDVDRip", "HD-DVDRip"],
	["BluRay", "Blu-Ray", "MBluRay"],
	["WEB-DL", "WEB", "WEBDL"],
	["Webrip", "WebRip", "WEBRip", "WEBRIP"],
	["TVRip", "TV"],
	["CAM"],
	["HDCAM", "HD-CAM", "HD CAM"],
	["R2", "R5", "R6"],
	["TELESYNC", "TS"],
	["HDTS", "HD-TS", "HD TS"],
	["TELECINE", "TC"],
	["SiteRip"],
	["PPV"],
	["VHSRip"],
	["IMGSet"],
	["Mixed"],
];

our $tvEncoders = [
	["XviD", "XVID", "XvidHD"],
	["DivX"],
	["x264", "X264"],
	["x264-Hi10p", "Hi10p", "10-bit"],
	["AVC", "h.264", "h264"],
	["mpeg2", "mpeg-2"],
	["VC-1", "VC1"],
	["WMV", "WMV-HD"],
	["h.264 Remux", "h264 Remux", "VC-1 Remux", "VC1 Remux", "MPEG2 Remux", "Remux"],
];

our $musicReleaseTypes = [
	["Album"],
	["Soundtrack"],
	["EP"],
	["Anthology"],
	["Compilation"],
	["DJ Mix"],
	["Single"],
	["Live album"],
	["Remix"],
	["Bootleg"],
	["Interview"],
	["Mixtape"],
	["Unknown"],
];

our $musicFormats = [
	["MP3"],
	["FLAC"],
	["Ogg","Ogg Vorbis"],
	["AAC"],
	["AC3"],
	["DTS"],
];

our $musicBitrates = [
	["192"],
	["APS (VBR)"],
	["V2 (VBR)","V2"],
	["V1 (VBR)","V1"],
	["256"],
	["APX (VBR)"],
	["V0 (VBR)","V0"],
	["q8.x (VBR)"],
	["320"],
	["Lossless"],
	["24bit Lossless"],
	["Other"],
];

our $musicMedia = [
	["CD"],
	["DVD"],
	["Vinyl"],
	["Soundboard"],
	["SACD"],
	["DAT"],
	["Cassette"],
	["WEB"],
	["Blu-ray"],
	["Other"],
];

our $otherReleaseNameStuff = [
	["3D", "After Hours", "BOXSET", "BoxSet", "BOX-SET", "Box-Set", "CUSTOM", "Custom",
	"Demo", "DEMO", "demo", "DK", "DKSUBS", "DKSubs",
	"DANISH", "DANiSH", "DUTCH", "NL", "NLSUBBED", "ENG", "FI", "FLEMISH", "FLEMiSH",
	"FINNISH", "FiNNiSH", "DE", "FRENCH", "GERMAN", "HE", "HEBREW", "HebSub", "ICELANDIC", "iCELANDiC",
	"INTERNAL", "iNTERNAL", "Internal", "LIMITED", "LiMiTED", "MULTISUBS", "MULTiSUBS",
	"NLSUBBED", "NORWEGIAN", "NORWEGiAN", "NO", "NORDIC", "NORDiC", "NTSC", "PAL",
	"PL", "PO", "PLDUB", "POLISH", "POLiSH", "PROPER",
	"RO", "ROMANIAN", "ROMANiAN", "ReEncode", "REENCODE", "READ.NFO", "READNFO", "REAL", "RERIP", "RERiP", "RePack", "REPACK",
	"DVDSCR", "DVDScr", "DVDSCREENER", ,"DVDScreener", "DVD-SCREENER", "DVD-Screener", "SCR", "Scr", "SCREENER", "Screener",
	"SPANISH", "SPANiSH", "STV", "SE", "SWEDISH", "SWEDiSH", "SWESUB", "XXX",
	"FS", "WS", "R2", "R5", "R6", "RC", "iNT", "XXX", "DISC1", "DISC2", "DISC3", "DISC4",
	"DTS", "DTS-HD", "DTS-HD MA", "DTS MA",
	"DTS-HD MA5.1", "DTS-HD MA5 1", "DTSHD-MA5 1", "DTSHD-MA5.1",
	"DTS-HD MA 5.1", "DTS-HD MA 5 1", "DTSHD-MA 5 1", "DTSHD-MA 5.1",
	"DTS-HD MA6.1", "DTS-HD MA6.1", "DTSHD-MA6 1", "DTSHD-MA6.1",
	"DTS-HD MA 6.1", "DTS-HD MA 6.1", "DTSHD-MA 6 1", "DTSHD-MA 6.1",
	"DTS-HD MA7.1", "DTS-HD MA7 1", "DTSHD-MA7 1", "DTSHD-MA7.1",
	"DTS-HD MA 7.1", "DTS-HD MA 7 1", "DTSHD-MA 7 1", "DTSHD-MA 7.1",
	"AC3", "DD5.1", "DD5 1"],
];
our $otherReleaseNameStuffLowerCase = [[]];
for my $o (@{$otherReleaseNameStuff->[0]}) {
	push @{$otherReleaseNameStuffLowerCase->[0]}, lc $o;
}

1;
