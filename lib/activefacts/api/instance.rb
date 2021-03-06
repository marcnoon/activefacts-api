#
#       ActiveFacts Runtime API
#       Instance (mixin module for instances of a ObjectType - a class with ObjectType mixed in)
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# Instance methods are extended into all instances, whether of value or entity types.
#
module ActiveFacts
  module API
    # Every Instance of a ObjectType (A Value type or an Entity type) includes the methods of this module:
    module Instance
      # What constellation does this Instance belong to (if any):
      attr_accessor :constellation

      def initialize(args = []) #:nodoc:
        unless (self.class.is_entity_type)
          begin
            super(*args)
          rescue ArgumentError => e
            e.message << " constructing a #{self.class}"
            raise
          end
        end
      end

      # Verbalise this instance
      def verbalise
        # This method should always be overridden in subclasses
      end

      # De-assign all functional roles and remove from constellation, if any.
      def retract
        # Delete from the constellation first, while it remembers our identifying role values
        @constellation.__retract(self) if @constellation

        # Now, for all roles (from this class and all supertypes), assign nil to all functional roles
        # The counterpart roles get cleared automatically.
        ([self.class]+self.class.supertypes_transitive).each do |klass|
          klass.roles.each do |role_name, role|
            next if role.unary?
            counterpart = role.counterpart
            if role.unique
              # puts "Nullifying mandatory role #{role.name} of #{role.object_type.name}" if counterpart.mandatory

              send role.setter, nil
            else
              # puts "Not removing role #{role_name} from counterpart RoleValues #{counterpart.name}"
              # Duplicate the array using to_a, as the RoleValues here will be modified as we traverse it:
              send(role.name).to_a.each do |v|
                v.send(counterpart.setter, nil)
              end
            end
          end
        end
      end

      module ClassMethods #:nodoc:
        include ObjectType
        # Add Instance class methods here
      end

      def Instance.included other #:nodoc:
        other.send :extend, ClassMethods
      end
    end
  end
end
