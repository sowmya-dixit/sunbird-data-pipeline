require 'securerandom'
require 'pry'
require 'geocoder'
require 'date'
# require 'ruby-progressbar'
require_relative '../../data-indexer/indexers.rb'

module Generator
  DEVICES = 25
  USERS = 200
  SESSIONS = 600
  class Location
    SLEEP_INTERVAL=0.2
    ADDRESS_COMPONENTS_MAPPINGS={
      city: :locality,
      district: :administrative_area_level_2,
      state: :administrative_area_level_1,
      country: :country
    }
    attr_reader :loc,:city,:district,:state,:country
    def initialize(loc)
      @loc=loc
      # @results=reverse_search
      # set_identity
    end
    private
    def reverse_search
      sleep(SLEEP_INTERVAL)
      Geocoder.search(loc)
    end
    def set_identity
      @city = get_name(:city)
      @district = get_name(:district)
      @state = get_name(:state)
      @country = get_name(:country)
      raise 'Location not set!' if(@city&&@district&&@state&&@country).nil?
    end
    def get_name(type)
      begin
        result = @results.find{|r|!r.address_components_of_type(ADDRESS_COMPONENTS_MAPPINGS[type]).empty?}
        result.address_components_of_type(ADDRESS_COMPONENTS_MAPPINGS[type]).first['long_name']
      rescue => e
        ""
      end
    end
  end
  class User
    attr_reader :uid
    def initialize
      @uid = SecureRandom.uuid
    end
  end
  class Device
    ANDROID_VERS = ['Android 5.0','Android 4.4','Android 4.1','Android 4.0']
    MAKES = ['Make A','Make B','Make C','Make D','Make E']
    attr_reader :id,:os,:make,:spec,:location
    def initialize(loc="#{rand(12.0..20.0)},#{rand(74.0..78.0)}")
      @id = SecureRandom.uuid
      @os = ANDROID_VERS.sample
      @make = MAKES.sample
      @location = Location.new(loc)
      @spec = "v1,1,.01,16,1,2,1,1,75,0"
    end
    def loc=(loc)
      @location = Location.new(loc)
    end
    def to_json
      {
        id: @id,
        os: @os,
        make: @make,
        loc: @location.loc,
        spec: @spec
      }
    end
    def deviceid
      return id
    end
  end
  class Session
    SECONDS_IN_A_DAY = 86400
    DAYS = 10
    END_TIME = DateTime.now
    START_TIME = END_TIME - DAYS*SECONDS_IN_A_DAY
    GE_GENIE_START = 'GE_GENIE_START'
    GE_GENIE_END = 'GE_GENIE_END'
    GE_SIGNUP = 'GE_SIGNUP'
    SESSION_START_EVENT = 'GE_SESSION_START'
    SESSION_END_EVENT = 'GE_SESSION_END'
    GE_LAUNCH_GAME = 'GE_LAUNCH_GAME'
    GE_CREATE_USER = 'GE_CREATE_USER'
    GE_CREATE_PROFILE = 'GE_CREATE_PROFILE'
    OE_START = 'OE_START'
    OE_ASSESS = 'OE_ASSESS'
    OE_END = 'OE_END'
    GE_GAME_END = 'GE_GAME_END'
    MIN_SESSION_TIME = 120
    MAX_SESSION_TIME = 300
    OLD_MODE = 'NO_LOC_IN_SESSION'
    NEW_MODE = 'LOC_IN_SESSION'
    attr_reader :sid
    def initialize(user,device,start_time=rand(START_TIME..END_TIME),mode=NEW_MODE)
      @mode=mode
      @sid = SecureRandom.uuid
      @start  = start_time
      @finish = @start+Rational(rand(120..300), 86400)
      @user = user
      @device = device
      @signup = (@start - Rational(rand(1..24),86400))
      @startup = (@signup - Rational(rand(1..24),86400))
      @shutdown = (@finish + Rational(rand(1..24),86400))
      @createuser = @start+ Rational(4,86400)
      @create_profile = @createuser + Rational(1,86400)
      @gamestart = @start+ Rational(6,86400)
      @oe_start = @gamestart + Rational(1,86400)
      @oe_access = @oe_start + Rational(1,86400)
      @oe_end = @oe_access + Rational(1,86400)
      @gameend  = @oe_end + Rational(1,86400)
    end
    def to_json
      events.to_json
    end
    def events(user_with_profile=false)
      p_event = {
        eid: GE_CREATE_PROFILE,
        mid: SecureRandom.uuid,
        ets: (@create_profile).strftime('%Q').to_i,
        ver: "2.0",
        gdata: {
          id: "genie.android",
          ver: "1.0"
        },
        sid: @sid,
        uid: @user.uid,
        did: @device.id,
        edata: {
          eks: {
            uid: @user.uid,
            handle: "handle",
            gender: "male",
            age: 7,
            standard: 2,
            language: "en",
            day: 21,
            month: 11
          }
        }
      }
      e = [
        {
          eid: GE_GENIE_START, # unique event ID
          mid: SecureRandom.uuid,
          ets: @startup.strftime('%Q').to_i,
          ver: "2.0",
          gdata: {
             id: "genie.android",
             ver: "1.0"
          },
          sid: "",
          uid: "",
          did: @device.id,
          edata: {
             eks: {
                dspec: {
                   os: @device.os,
                   make: @device.make, # device make and model
                   mem: 1000, # total mem in MB
                   idisk: 8, # total internal disk in GB
                   edisk: 32, # total external disk (card) in GB
                   scrn: 4.5, # in inches
                   camera: "13,1.3", # primary and secondary camera
                   cpu: "2.7 GHz Qualcomm Snapdragon 805 Quad Core",
                   sims: 2, # number of sim cards
                   cap: ["GPS","BT","WIFI","3G","ACCEL"] # capabilities enums
                },
                loc: @device.location.loc, # Location in lat,long format
                ldata: {
                  locality: @device.location.city,
                  district: @device.location.district,
                  state: @device.location.state,
                  country: @device.location.country
                }
             }
          }
        },
        {
          eid: GE_CREATE_USER,
          mid: SecureRandom.uuid,
          ets: (@createuser).strftime('%Q').to_i,
          ver: "2.0",
          gdata: {
            id: "genie.android",
            ver: "1.0"
          },
          sid: @sid,
          uid: @user.uid,
          did: @device.id,
          edata: {
            eks: {
              uid: @user.uid,
              loc: @device.location.loc # Location in lat,long format
            }
          }
        },
        {
          eid: SESSION_START_EVENT,
          mid: SecureRandom.uuid,
          ets: @start.strftime('%Q').to_i,
          ver: "2.0",
          gdata: {
            id: "genie.android",
            ver: "1.0"
          },
          sid: @sid,
          did: @device.id,
          uid: @user.uid,
          edata: {
            eks:{
               ueksid: "",
               loc: @device.location.loc
            }
          }
        },
        {
          eid: GE_LAUNCH_GAME,
          mid: SecureRandom.uuid,
          ets: (@gamestart).strftime('%Q').to_i,
          ver: "2.0",
          gdata: {
            id: "genie.android",
            ver: "1.0"
          },
          sid: @sid,
          uid: @user.uid,
          did: @device.id,
          edata: {
            eks:{
              gid: "lit.scrnr.kan.android",
              err: ""
            }
          }
        },
        {
          eid: OE_START,
          mid: SecureRandom.uuid,
          uid:  @user.uid,
          sid: @sid,
          ets: (@oe_start).strftime('%Q').to_i,
          edata: {
            eks: {},
            ext: {}
          },
          did:  @device.id,
          ver: "2.0",
          gdata: {
            id: "genie.android",
            ver: "1.0"
          },
        },
        {
            eid: OE_ASSESS,
            mid: SecureRandom.uuid,
            uid:  @user.uid,
            sid: @sid,
            ets: (@oe_access).strftime('%Q').to_i,
            edata: {
              eks: {
                  atmpts: 1,
                  exlength: 0,
                  exres: [],
                  failedatmpts: 0,
                  length: 0,
                  maxscore: 1,
                  mc: [
                      "M92"
                  ],
                  pass: "No",
                  qid: "q_2_sub",
                  qlevel: "",
                  qtype: "SUB",
                  res: [],
                  score: 0,
                  subj: "NUM",
                  uri: ""
              },
              ext: {
                  "Question": ""
              }
            },
            did:  @device.id,
            ver: "2.0",
            gdata: {
              id: "genie.android",
              ver: "1.0"
            },
        },
        {
          eid: OE_END,
          mid: SecureRandom.uuid,
          uid:  @user.uid,
          sid: @sid,
          ets: (@oe_end).strftime('%Q').to_i,
          edata: {
            eks: {
              length: 637
            },
            ext: {}
          },
          did:  @device.id,
          ver: "2.0",
          gdata: {
            id: "genie.android",
            ver: "1.0"
          },
        },
        {
          eid: GE_GAME_END,
          mid: SecureRandom.uuid,
          ets: (@gameend).strftime('%Q').to_i,
          ver: "2.0",
          gdata: {
            id: "genie.android",
            ver: "1.0"
          },
          sid: @sid,
          uid: @user.uid,
          did: @device.id,
          edata: {
            eks:{
              gid: "lit.scrnr.kan.android",
              length: ((@gameend - @gamestart).to_i/3600.0).round(2)
            }
          }
        },
        {
          eid: SESSION_END_EVENT,
          mid: SecureRandom.uuid,
          ets: @finish.strftime('%Q').to_i,
          ver: "2.0",
          gdata: {
            id: "genie.android",
            ver: "1.0"
          },
          sid: @sid,
          did: @device.id,
          uid: @user.uid,
          edata: {
            eks: {
              length: ((@finish - @start).to_i/3600.0).round(2)
            }
          }
        },
        {
          eid: GE_GENIE_END, # unique event ID
          mid: SecureRandom.uuid,
          ets: @shutdown.strftime('%Q').to_i,
          ver: "2.0",
          gdata: {
             id: "genie.android",
             ver: "1.0"
          },
          sid: "",
          uid: "",
          did: @device.id,
          edata: {
             eks: {
                length: ((@shutdown-@startup).to_i/3600.0).round(2)
             }
          }
        },
      ]
      create_user_index = e.find_index {|x| x[:eid] == 'GE_CREATE_USER'}
      e.delete_at(create_user_index) if user_with_profile
      e.insert(create_user_index, p_event) if user_with_profile
      if(@mode == OLD_MODE)
        session_start_event = e.select{|ev|ev[:eid]==SESSION_START_EVENT}
        session_start_event[0][:edata][:eks].delete(:loc)
      end
      e
    end

    def total_events_with_session
      events.find {|s| !s.empty?}.size
    end
  end

  class Runner
    def initialize(opts={})
      @user_pool = Array.new(opts[:users]||USERS) {User.new}
      @device_pool = Array.new(opts[:devices]||DEVICES) {Device.new}
      @sessions = opts[:sessions]
      file = "#{ENV['EP_LOG_DIR']}/#{self.class.name.gsub('::','')}.log"
      @logger = Logger.new(file)
    end
    def run
      (@sessions||SESSIONS).times do
        session = Session.new(@user_pool.sample,@device_pool.sample)
        # @logger.info "SESSION #{session.to_json}"
        yield session,@logger
      end
    end
  end
end
