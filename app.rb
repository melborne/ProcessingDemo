# encoding: UTF-8
require "json"

F = { milk: ['public/milk-tea-coffee.tsv', '\t', [5, 2.5, 10]],
      census: ['public/census.csv', ' ', [500, 250, 10]]  }

configure do
  APP_TITLE = "Visualizing-Data with Processing Demo"
end

get '/' do
  redirect '/milk'
end

paths = ['milk', 'census']
paths.each_with_index do |path, i|
  get "/#{path}" do
    @link = paths[(i+1)%2]
    haml :index
  end

  get "/#{path}.json" do
    redirect path unless request.xhr?
    content_type :json
    parse_data(*F[path.intern]).to_json
  end
end

get '/style.css' do
  scss :style
end

helpers do
  def parse_data(path, sep, intervals)
    q = {}
    File.open(path) do |file|
      q['label'] = retrieve_label(file.lines.first, sep) 
      q['data'] = retrieve_data(file.lines, sep)
      all_data = q['data'].map { |d| d[0..-2] }.flatten
      q['dataMin'], q['dataMax'] = all_data.min.floor, all_data.max.ceil
      q['intervals'] = intervals
    end
    q
  end

  def retrieve_label(line, sep)
    date_label, *category_labels = line.split(/#{sep}+/)
    category_labels.map { |d| d.strip.chomp } << date_label
  end

  def retrieve_data(lines, sep)
    lines.inject([]) do |mem, line|
      date, *categories = line.split(/#{sep}+/)
      #split year, month, day from 8 digits
      date = date.tr("０-９","0-9").gsub(/\D/,'').unpack("A4A2A2").map(&:to_i)
      categories = categories.map { |d| d.gsub(/[^.\d]/, '').to_f }
      mem << categories.push(date)
    end
  end
end
