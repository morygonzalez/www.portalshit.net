module Lokka
  module AmazonAssociate
    module CacheControllable
      def path
        @path ||= begin
                    dir = File.expand_path("tmp/amazon/#{@kind}")
                    FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
                    File.join(dir, "#{@item_id}.#{@kind}")
                  end
      end

      def body
        @body ||= File.read(path)
      end

      private

      def cache_alive?
        return false unless File.exist?(path)
        return false if File.zero?(path)
        File.mtime(path) > Time.now - 60 * 60 * 24
      end

      def wirite_or_touch_cache
        File.open(path, 'w') {|f| f.print result }
      rescue StandardError
        FileUtils.touch path
      end
    end
  end
end
