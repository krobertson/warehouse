module Warehouse
  module Syncer
    class Base
      attr_reader :connection, :repo, :num, :silo

      def self.process(connection, repo, silo, num)
        new(connection, repo, silo, num).process
      end

      def initialize(connection, repo, silo, num)
        @connection, @repo, @silo, @num = connection, repo, silo, num
      end
      
      def process
        puts "Syncing #{@num} Revision(s)", :debug
        authors = {}

        yield authors

        unless authors.empty?
          users = @connection[:users].where(:login => authors.keys).inject({}) do |memo, user|
            memo.update(user[:login] => user[:id])
          end
          authors.each do |login, changed_at|
            next unless users[login]
            update_user_activity({:id => users[login], :login => login}, changed_at)
          end
        end
        CacheKey.sweep_cache
      end

    protected
      def update_user_activity(user, changed_at)
        changesets_count = @connection[:changesets].where(:repository_id => @repo[:id], :author => user[:login]).select(:id.COUNT)
        @connection[:permissions].where(:user_id => user[:id], :repository_id => @repo[:id]).update \
          :last_changed_at => changed_at, :changesets_count => changesets_count
      end

      def puts(str, level = :info)
        if level == :raw
          super(str)
        else
          Warehouse::Command.logger && Warehouse::Command.logger.send(level, str)
        end
      end
    end
  end
end