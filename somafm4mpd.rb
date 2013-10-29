#!/usr/bin/ruby
# coding: utf-8
#
# Play SomaFM <http://soma.fm/> Playlists via MPD server.
# Copyright (c) 2013 Paul Philippov <themactep@gmail.com>
#
# This work is released under GPLv2 License.
#
# Last Change: 29-Oct-2013.
#

@mpd_host = "192.168.0.4"
@mpd_port = "6600"

## YOU DON'T WANT TO EDIT ANYHTING BELOW THIS LINE

@mpc_app = `which mpc`.chomp
if @mpc_app == ""
  puts "This script requires mpc! Aborting..."
  exit 1
end

@playlist = nil

SOMA_PLAYLISTS = [
  { id: "bagel",          name: "BAGeL Radio"            },
  { id: "beatblender",    name: "Beat Blender"           },
  { id: "brfm",           name: "Black Rock FM"          },
  { id: "bootliquor",     name: "Boot Liquor"            },
  { id: "christmas",      name: "Christmas Lounge"       },
  { id: "xmasrocks",      name: "Christmas Rocks!"       },
  { id: "cliqhop",        name: "cliqhop idm"            },
  { id: "covers",         name: "Covers"                 },
  { id: "deepspaceone",   name: "Deep Space One"         },
  { id: "events",         name: "DEF CON Radio"          },
  { id: "digitalis",      name: "Digitalis"              },
  { id: "doomed",         name: "Doomed"                 },
  { id: "dronezone",      name: "Drone Zone"             },
  { id: "dubstep",        name: "Dub Step Beyond"        },
  { id: "earwaves",       name: "Earwaves"               },
  { id: "folkfwd",        name: "Folk Forward"           },
  { id: "groovesalad",    name: "Groove Salad"           },
  { id: "airwaves",       name: "Iceland Airwaves"       },
  { id: "illstreet",      name: "Illinois Street Lounge" },
  { id: "indiepop",       name: "Indie Pop Rocks!"       },
  { id: "lush",           name: "Lush"                   },
  { id: "missioncontrol", name: "Mission Control"        },
  { id: "poptron",        name: "PopTron"                },
  { id: "secretagent",    name: "Secret Agent"           },
  { id: "sf1033",         name: "SF 10-33"               },
  { id: "sonicuniverse",  name: "Sonic Universe"         },
  { id: "spacestation",   name: "Space Station Soma"     },
  { id: "suburbsofgoa",   name: "Suburbs of Goa"         },
  { id: "thetrip",        name: "The Trip"               },
  { id: "u80s",           name: "Underground 80s"        },
  { id: "xmasinfrisko",   name: "Xmas in Frisko"         },
]

def soma_playlist_list_length
  SOMA_PLAYLISTS.size
end

def soma_playlist_list_numbers
  (1..soma_playlist_list_length)
end

def soma_playlist_by_number(n)
  SOMA_PLAYLISTS[n-1]
end

def soma_playlist_by_name(name)
  SOMA_PLAYLISTS.dup.keep_if {|playlist| playlist[:name] == name}.first
end

def soma_playlist_url(id)
  "http://somafm.com/#{id}.pls"
end

def list_SOMA_PLAYLISTS
  clean_screen

  puts "List of SomaFM Playlists"
  puts "-" * 60

  half = (soma_playlist_list_length / 2.0).ceil
  (1..half).each do |i1|
    i2 = i1 + half
    if i2 > soma_playlist_list_length
      puts "%3d. %-24s" % [i1, soma_playlist_by_number(i1)[:name]]
    else
      puts "%3d. %-24s %3d. %-24s" % [i1, soma_playlist_by_number(i1)[:name], i2, soma_playlist_by_number(i2)[:name]]
    end
  end
  puts "-" * 60
end

def mpc
  @mpc ||= "#{@mpc_app} --host #{@mpd_host} --port #{@mpd_port}"
end

def mpc_clear
  %x[#{mpc} clear]
end

def mpc_current_track
  %x[#{mpc} current --format "%title%"].chomp
end

def mpc_load(playlist)
  %x[#{mpc} load "#{playlist}"]
end

def mpc_play
  %x[#{mpc} play]
end

def mpc_toggle_play
  %x[#{mpc} toggle]
end

def mpc_list_playlists
  %x[#{mpc} lsplaylists].split("\n")
end

def mpc_save_playlist(name)
  %x[#{mpc} save "#{name}"]
end

def clean_screen
  puts "\e[H\e[2J"
end

def read_input
  print "Playlist # or '?' for help: "
  gets.chomp
end

def show_help
  puts " - enter playlist number to load"
  puts " - enter 'i' to get information on playing track"
  puts " - enter 'l' to show available playlists"
  puts " - enter 'p' to toggle play/pause"
  puts " - enter 's' to save recent playlist to MPD"
  puts " - enter 'q' to quit the program"
end

def show_current_playlist
  if @playlist
    puts "Loaded: \"#{@playlist[:name]}\""
  else
    puts "Unknown playlist"
  end
end

def show_current_track
  cnt = 0
  loop do
    track = mpc_current_track
    if track != "" and !track.start_with?("SomaFM:")
      puts track
      break
    end

    if (cnt += 1) > 1000
      puts "!! Timeout. Please try again."
      break
    end
  end
end

def tune_to_soma
  if @playlist
    print "Loading \"#{@playlist[:name]}\" ... "
    mpc_clear
    mpc_load(soma_playlist_url(@playlist[:id]))
    mpc_play
    print "\r" << " " * 80 << "\r"
    show_current_playlist
  else
    puts "Unknown playlist. Please try again."
  end
end

### Main routine

list_SOMA_PLAYLISTS
loop do
  case read_input
  when "?"
    show_help

  when "i"
    show_current_track

  when "l"
    list_SOMA_PLAYLISTS

  when "p"
    mpc_toggle_play

  when "q"
    puts "Good bye!"
    exit 0

  when "s"
    if @playlist
      name = "SomaFM: " << @playlist[:name]
      unless mpc_list_playlists.include?(name)
        mpc_save_playlist(name)
        puts "Playlist \"#{name}\" saved."
      else
        puts "Playlist \"#{name}\" already exists!"
      end
    else
      puts "Sorry, cannot save unknown playlist."
    end

  when /^(\d+)$/
    number = $1.to_i
    if soma_playlist_list_numbers.include?(number)
      @playlist = soma_playlist_by_number(number)
      tune_to_soma
    else
      puts "Sorry, the number is out of range. Please try again."
    end

  else
    puts "Sorry, I didn't understand that. Please try again."
  end
end
