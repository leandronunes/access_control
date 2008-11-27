module PermissionCheck
  
  module ClassMethods
    # Declares the +permission+ need to be able to access +action+.
    #
    # * +permission+ must be a symbol or string naming the needed permission to
    #   access the specified actions.
    # * +target+ is the object over witch the user would need the specified
    #   permission and must be specified as a symbol or the string 'global'. The controller using
    #   +target+ must respond to a method with that name returning the object
    #   against which the permissions needed will be checked or if 'global' is passed it will be 
    #   cheked if the assignment is global
    # * +accessor+ is a mehtod that returns the accessor who must have the permission. By default
    #   is :user
    # * +action+ must be a hash of options for a before filter like 
    #   :only => :index or :except => [:edit, :update] by default protects all the actions
    def protect(permission, target_method, accessor_method = :user, actions = {})
      actions, accessor_method = accessor_method, :user if accessor_method.kind_of?(Hash)
      before_filter actions do |c|    
          target = target_method.kind_of?(Symbol) ? c.send(target_method) : target_method
          accessor = accessor_method.kind_of?(Symbol) ? c.send(accessor_method) : accessor_method
          unless accessor && accessor.has_permission?(permission.to_s, target)
#            c.instance_variable_set('@b', [accessor, permission, target])
            c.send(:render, :file => access_denied_template_path, :status => 403) && false
          end
      end
    end

    def access_denied_template_path
      if File.exists?(File.join(RAILS_ROOT, 'app', 'views','access_control' ,'access_denied.rhtml'))
        file_path = File.join(RAILS_ROOT, 'app', 'views','access_control' ,'access_denied.rhtml')
      else
        file_path = File.join(File.dirname(__FILE__),'..', 'views','access_denied.rhtml')
      end
    end
  end

  def self.included(including)
    including.send(:extend, PermissionCheck::ClassMethods)
  end
end
