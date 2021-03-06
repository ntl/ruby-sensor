require 'thread'

module Instana
  class Processor

    def initialize
      @queue = Queue.new
    end

    # Adds a trace to the queue to be processed and
    # sent to the host agent
    #
    # @param [Trace] the trace to be added to the queue
    def add(trace)
      @queue.push(trace)
    end

    ##
    # send
    #
    # Sends all traces in @queue to the host
    # agent
    #
    # FIXME: Add limits checking here in regards to:
    #   - Max HTTP Post size
    #   - Out of control/growing queue
    #   - Prevent another run of the timer while this is running
    #
    def send
      return if @queue.empty?

      size = @queue.size
      if size > 10
        Instana.logger.debug "Trace queue is #{size}"
      end

      ::Instana.agent.report_spans(queued_spans)
    end

    # Get the number traces currently in the queue
    #
    def queue_count
      @queue.size
    end

    # Retrieves all of the traces in @queue and returns
    # the sum of their raw spans.
    # This is used by Processor::send and in the test suite.
    # Note that traces retrieved with this method are removed
    # entirely from the queue.
    #
    def queued_spans
      return [] if @queue.empty?

      spans = []
      until @queue.empty? do
        # Non-blocking pop; ignore exception
        trace = @queue.pop(true) rescue nil
        trace.spans.each do |s|
          spans << s.raw
        end
      end
      spans
    end

    # Retrieves all of the traces that are in @queue.
    # Note that traces retrieved with this method are removed
    # entirely from the queue.
    #
    def queued_traces
      return [] if @queue.empty?

      traces = []
      until @queue.empty? do
        # Non-blocking pop; ignore exception
        traces << @queue.pop(true) rescue nil
      end
      traces
    end

    # Removes all traces from the @queue.  Used in the
    # test suite.
    #
    def clear!
      return [] if @queue.empty?

      until @queue.empty? do
        # Non-blocking pop; ignore exception
        @queue.pop(true) rescue nil
      end
    end
  end
end
