# -*- encoding : utf-8 -*-
module WandoGrids
  # Author:   Justin
  # Comment:  构造Wando.Grid的后台数据
  # date:     2013-03-04
  # params:   前台wando_grid默认传入参数，用于数据查找，考虑不需要传该参数
  # object:   传入你需要获取数据的 object 名字,object.class必须为ActivityRecord
  # options:  传入附加的条件
  # loadData: 是否自动加载数据

  # wando_grid的入口函数,返回请求记录，和记录总数
  def wando_grid(params, object, option = {}, toLoadData = true)
    object, result = wando_grid_in_json(params, object, option, toLoadData)
    
    result = { :total => object.count, :result => result }
    render_json  result
  end

  # 构造JSON格式的Grid记录
  def wando_grid_in_json(params, object, option, toLoadData)
    unless toLoadData
      return [], []
    end

    order = "updated_at DESC"
    unless params[:sort].nil?
      JSON.parse(params[:sort]).each do |k|
        if object.column_names.include?(k["property"])
          order = k["property"].to_s + " " + k["direction"].to_s
        else
          order = 'id' + ' ' + k["direction"].to_s
        end
      end
    end

    default_options = {
                        :order  => params[:order],
                        :offset => params[:offeset].to_i,
                        :start  => params[:start].to_i || 0,
                        :limit  => params[:limit].to_i || 20
                      }
    fields, column_name, result = [], [], []

    relations = JSON.parse(params[:columnsConfig])
    relations.each do |o ,e|
      fields << e
      column_name << o
    end

    column_name.push("id")
    offset = default_options[:offeset].to_i + default_options[:start].to_i
    records = object.where(option)
                    .order(order)
                    .limit(params[:limit])
                    .offset(offset)
                    .search(build_filter_options(object, params[:filter]))
                    .result(:distinct => true)
                    .provide(*column_name)

    records.each do |r|
      result << Hash[r.map {|k, v| [relations[k], v] }]
    end

    return object.where(option), result
  end

  # 通过Grid的Field来构造Record记录
  def get_record_by_fields(fields, object, option = {})
    fields = JSON.parse(fields) unless fields.is_a?(Array)
    records = object.where(option).provide(*fields)

    result = { :result => records }
    render_json result
  end

  # Grid每一列的查询
  def build_filter_options(object, filter_hash)
    return {} if filter_hash.nil?

    fs          = {}
    filter_hash = filter_hash.delete_if { |key, value| value.blank? }

    filter_hash.each do |columns, fvals|
      fs_tmp        = {}
      relation      = JSON.parse(params[:columnsConfig])
      gf_field      = relation.invert[fvals[:field]].downcase.gsub("/", "_")
      gf_type       = fvals[:data][:type].downcase
      gf_value      = fvals[:data][:value]
      gf_comparison = fvals[:data][:comparison]

      case gf_type
        when 'numeric'
          case gf_comparison
            when 'gt'
              gf_field += "_gt"
            when 'lt'
              gf_field += "_lt"
            when 'eq'
              gf_field += "_eq"
            when 'ne'
              gf_field += "_neq"
          end

          fs_tmp[gf_field.to_sym] = gf_value.to_i
        when 'string'
          gf_field += "_cont"

          fs_tmp[gf_field.to_sym] = gf_value.to_s
        when 'boolean'
          gf_value = gf_value.downcase

          if gf_value == 'true' or gf_value == 'false'
            gf_field += "_" + gf_value
            fs_tmp[gf_field.to_sym] = "1"
          end
        when 'list'
          gf_field += "_cont"

          fs_tmp[gf_field.to_sym] = gf_value.to_s
        when 'date'
          case gf_comparison
            when 'gt'
              gf_field += '_gt'
            when 'lt'
              gf_field += '_lt'
            when 'eq'
              gf_field += '_eq'
            when 'ne'
              gf_field += '_neq'
          end

          fs_tmp[gf_field.to_sym] = gf_value
      end

      unless fs_tmp.empty?
        fs.merge!(fs_tmp)
      end
    end

    fs
  end

  def wando_grid_for_array params, array
   fields, column_name, result = [], [], []

   relations = JSON.parse(params[:columnsConfig])
   relations.each do |o ,e|
     fields << e
     column_name << o
   end

   column_name.push("id")
   records = array.provide(*column_name)

   records.each do |r|
     result << Hash[r.map {|k, v| [relations[k], v] }]
   end

   render :json => { :success => true, :total => array.count, :result => result }
    
  end
  
end
