module Intrigue
  module Model
    class ScanResult

      attr_accessor :id, :name, :tasks, :entities, :log
      attr_accessor :depth, :scan_type, :entity, :task_results
      attr_accessor :timestamp_start, :timestamp_end

      def self.key
        "scan_result"
      end

      def key
        "#{Intrigue::Model::ScanResult.key}"
      end

      def initialize(id,name)
        @id = id
        @name = name
        @timestamp_start = Time.now.getutc.to_s
        @timestamp_end = Time.now.getutc.to_s
        @depth=nil
        @scan_type =nil
        @entity = nil
        @task_results = []
        @options = []
        @entities = []
        @log = ScanResultLog.new(id,name); @log.save
      end

      def self.find(id)
        lookup_key = "#{key}:#{id}"
        result = $intrigue_redis.get(lookup_key)
        raise "Unable to find #{lookup_key}" unless result

        s = ScanResult.new("nope","nope")
        s.from_json(result)
        s.save

        # if we didn't find anything in the db, return nil
        return nil if s.name == "nope"
      s
      end

      def add_task_result(task_result)
        @task_results << task_result
        save
      end

      def add_entity(entity)
        @entities << entity
        save
      end

      def from_json(json)
        begin
          x = JSON.parse(json)
          @id = x["id"]
          @depth = x["depth"]
          @scan_type = x["scan_type"]
          @name = x["name"]
          @timestamp_start = x["timestamp_start"]
          @timestamp_end = x["timestamp_end"]
          @entity = Entity.find(x["entity_id"])
          @task_results = x["task_result_ids"].map{|y| TaskResult.find y } if x["task_result_ids"]
          @entities = x["entity_ids"].map{|y| Entity.find y } if x["entity_ids"]
          @log = ScanResultLog.find x["id"]

        rescue JSON::ParserError => e
          return nil
        end
      end

      def to_json
        to_hash.to_json
      end

      def to_hash
        {
          "id" => @id,
          "name" => @name,
          "scan_type" => @scan_type,
          "depth" => @depth,
          "timestamp_start" => @timestamp_start,
          "timestamp_end" => @timestamp_end,
          "entity_id" => @entity.id,
          "task_result_ids" => @task_results.map{|y| y.id },
          "entity_ids" => @entities.map {|y| y.id },
          "options" => @options
        }
      end

      def to_s
        to_json
      end

      def save
        lookup_key = "#{key}:#{@id}"
        $intrigue_redis.set lookup_key, to_json
      end

    end
  end
end
