#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013 Genome Research Ltd.
module StateChangers
  class QcCompletablePlateStateChanger
    include PlatesController::LabwareWrangler

    attr_reader :labware_uuid, :api
    private :api
    attr_reader :user_uuid

    def initialize(api, labware_uuid, user_uuid)
      @api, @labware_uuid, @user_uuid = api, labware_uuid, user_uuid

    end

    def move_to!(state, reason = nil, customer_accepts_responsibility = false)
      state_details = {
        :target       => labware_uuid,
        :user         => user_uuid,
        :target_state => state,
        :reason       => reason,
        :customer_accepts_responsibility => customer_accepts_responsibility
      }

      case state
      when 'qc_complete' then filtered_state_change!(state_details)
      when 'cancelled'   then filtered_state_change!(state_details)
      else passive_state_change!(state_details)
      end
    end

    def labware
      @labware ||= locate_labware_identified_by(labware_uuid)
    end

    # Changes the state of plates excluding failed wells...
    def filtered_state_change!(state_details)
      well_locations = labware.wells.reject {|w| w.state == 'failed'}.map(&:location)

      api.state_change.create!(
        state_details.reverse_merge(:contents => well_locations)
      )
    end

    # Change the state without using the labware directly
    def passive_state_change!(state_details)
      api.state_change.create!(state_details)
    end
  end

  def self.lookup_for(purpose_uuid)
    details = Settings.purposes[purpose_uuid] or raise "Unknown purpose UUID: #{purpose_uuid}"
    details[:state_changer_class].constantize
  end
end
