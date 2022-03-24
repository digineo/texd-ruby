# frozen_string_literal: true

module Texd
  # Cache is a simple LRU cache with a double linked list.
  # If the cache is full the last element from the list will be removed.
  class Cache
    class LinkedList
      attr_reader :head

      def add(node)
        if @head
          node.next       = @head
          node.prev       = @head.prev
          @head.prev.next = node
          @head.prev      = node
        else
          node.next = node
          node.prev = node
        end

        @head = node
      end

      def remove(node)
        if node.next == node
          # remove last element, should never happen
          @head = nil
        else
          node.prev.next = node.next
          node.next.prev = node.prev
          @head          = node.next if node == @head
        end
      end
    end

    class Node
      attr_reader :key
      attr_accessor :value, :prev, :next

      def initialize(key)
        @key = key
      end
    end

    attr_reader :list, :count, :capacity
    delegate :keys, to: :@hash

    def initialize(capacity)
      @list     = LinkedList.new
      @hash     = {}
      @mtx      = Mutex.new
      @count    = 0
      @capacity = capacity
    end

    def fetch(key)
      read(key) || write(key, yield)
    end

    def read(key)
      @mtx.synchronize do
        node = @hash[key]
        return unless node

        list.remove(node)
        list.add(node)
        node.value
      end
    end

    def write(key, value)
      @mtx.synchronize do
        node = @hash[key]

        if node
          list.remove(node)
        else
          node = add_node(key)
        end

        list.add(node)
        node.value = value
      end
    end

    private

    def add_node(key)
      node = Node.new(key)

      if count >= capacity
        last = list.head.prev
        @hash.delete(last.key)
        list.remove(last)
      else
        @count += 1
      end

      @hash[key] = node
      node
    end
  end
end
