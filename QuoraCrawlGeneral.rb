require "selenium-webdriver"
require 'rubygems'
require 'watir-webdriver'
require 'nokogiri'
require 'json'
require "sqlite3"
# require "mysql"

def slice_sub (link)
        if(link.include? "no_redirect")
                link.slice! "?no_redirect=1"
        end

        return link
end

def get_questions(begin_, end_, id_)

        questions_list_ = Array.new
        i = 0
        f = File.open(Dir.pwd+"/Questions"+id_.to_s+".txt", "r")
        f.each_line do |line|

          if(i >= begin_)
                questions_list_.push(line)
          end

          if (i == end_)
                break
          end

          i= i+1
        end
        f.close
        return questions_list_
end

def reload_database()

    i = 0
    questions_list_ = Array.new
    db = SQLite3::Database.open Dir.pwd+"/Quora_General_Data.db"
    db.execute 'SELECT * FROM List' do |row|
        print i
        i = i+1
        questions_list_.push(row)
    end

    return questions_list_
end

def write_questions_to_load_next_to_file(questions_list)
    f = File.open(Dir.pwd+"/Questions_to_crawl.txt", "w")
     questions_list.each do |line|
#	puts line
        f.write(line)
     end
end

def check_if_questions_are_to_be_written(questions_list, counter)
    if(counter == 100)
        counter = 0
        write_questions_to_load_next_to_file(questions_list)
    else 
        counter = counter + 1
    end
        
    return counter
end



def crawl(start_, end_, id_)

        questions_list = Array.new
        ques_save = Array.new
        answerers_save_links = Array.new
        tags_save = Array.new
        related_save = Array.new
        shares_ques_save = Array.new
        comments_ques_save = Array.new
        views_save = Array.new
        answers_json = Array.new
        shares_question_names = Array.new
        up_people = Array.new
        followers_save = ""
        restart_browser_count = 0
        universal_count = 0
        mutex = Mutex.new
        counter = 0

        db = SQLite3::Database.open Dir.pwd+"/Quora_Individual_Data"+id_.to_s.to_s+".db"

        # ---------------------
        b = Watir::Browser.new :phantomjs
        p b
        p "Starting to Go"
        b.goto 'http://www.quora.com'
        puts b.title
        b.text_field(:name => 'email').set 'jot321@gmail.com'
        b.text_field(:name => 'password').set 'jot968954901'
        sleep(3)
        b.send_keys :enter
        sleep(5)
        # ----------------------

        # db.execute "PRAGMA journal_mode=WAL"
        db.execute "CREATE TABLE IF NOT EXISTS Questions (Id INT , Question TEXT, Followers TEXT,Shares TEXT,No_of_Comments TEXT,Views TEXT,No_of_Answers TEXT)"
        db.execute "CREATE TABLE IF NOT EXISTS Answers (Q_Id INT ,Content TEXT, Answerer TEXT, Answerer_Link TEXT, Upvotes TEXT, No_of_Comments TEXT,No_of_Shares TEXT, Timestamp TEXT,Upvotes_People TEXT )"
        db.execute "CREATE TABLE IF NOT EXISTS Tags  (Q_Id INT, Tag TEXT)"
        db.execute "CREATE TABLE IF NOT EXISTS Shares (Q_Id INT, Name TEXT)"
        db.execute "CREATE TABLE IF NOT EXISTS Related_Questions (Q_Id INT, Question TEXT)"

        $db_list.execute "CREATE TABLE IF NOT EXISTS Users(Link TEXT)"
        $db_list.execute "CREATE TABLE IF NOT EXISTS Topics(Link TEXT)"
        $db_list.execute "CREATE TABLE IF NOT EXISTS List(Question TEXT)"

        questions_list = get_questions(start_,end_,4)
        # $questions_total = reload_database()

        inf_count = 1
        while inf_count > 0 do

                begin

                        puts "Begining"

                        sleep(0.5)
                        link_start = questions_list[0]
                        questions_list.shift

                        already_in_the_list = $questions_total.include? ( slice_sub(link_start))

                        if(already_in_the_list == true)

                                puts "Questions Repeated"
                                questions_list.shift
                                next

                        end

                        b.goto ("http://www.quora.com" + link_start)
                        puts "\t\tPage Opened --> " + link_start


                        # share_present = b.span(:class =>"repost_count_link").present?
                        # begin
                        #         if(share_present == true)
                        #                 b.div(:class => "QuestionActionBar").span(:class =>"repost_count_link").when_present.click
                        #                 b.div(:class =>"meta_item").wait_until_present
                        #         end
                        # rescue => ex
                        #         puts ex.backtrace
                        #         questions_list.push(link_start)
                        #         questions_list.shift
                        #         next
                        # end



                        page = Nokogiri::HTML(b.html)
                        old_num = ""
                        no_answers = page.css("div.answer_header h3")
                        no_answers.each{|link| old_num = link.text }
                        no_of_answers_final = old_num.scan(/\d/).join('')

                        question_sharing_people = page.css("div.question div.meta_item")
                        question_sharing_people.each{|name|
                                shares_question_names.push(name.to_s)
                        }


                        To load the page further for ajax requests to execute and asnsers to load
                        i=0
                        j=0
                        no_of_scrolls = (no_of_answers_final.to_i - 10 )/2
                        if(no_of_scrolls > 500)
                                no_of_scrolls = 500
                        end

                        while i < no_of_scrolls
                                b.execute_script "window.scrollTo(0,document.body.scrollHeight)"

                                if(j<10)
                                        begin
                                                b.links(:class, "more_link").each{|d|
                                                    puts d.text
                                                    if(d.present?)
                                                        d.click
                                                        # sleep(0.5)
                                                    end
                                                }
                                        rescue => ex
                                                puts ex.backtrace
                                                questions_list.push(link_start)
                                                questions_list.shift
                                                next
                                        end
                                end

                                sleep(0.5)
                                i += 1
                                j += 1

                        end


                        page = Nokogiri::HTML(b.html)

                        puts "\tPage added to Nokogiri"
                        # -------------------------------------

                        # Main Question
                        ques = page.css("span.inline_editor_value h1")
                        ques.each{|q| ques_save.push(q.text) }


                        # No. of Followers
                        followers = page.css("li.following_count a")
                        followers.each{|q| followers_save = q.text }
                        x = followers_save.scan(/\d/).join('')
                        followers_final = x.to_i



                        # Related Questions
                        links = page.css("a").select{|link| link['class'] == "question_link"}
                        links.each{|link|

                                related_save.push(link.text)
                                related_link_check = slice_sub(link['href'])
                                # ary = $db_list.execute "SELECT * from List WHERE Question = '"+related_link_check + "'"
                                already_in_the_list = $questions_total.include? ( slice_sub(link['href']))

                                if(already_in_the_list == false)
                                        questions_list.push( slice_sub(link['href'])  ) unless questions_list.include?( slice_sub(link['href']))
                                end
                        }


                        # No of shares for each question
                        shares = page.css("div.question span.repost_count_link")
                        shares.each{|s|
                                shares_ques_save.push(s.text)
                        }

                        # No of comments for each question
                        comments_ques = page.css("div.question a.view_comments span.count")
                        comments_ques.each{|s|
                                comments_ques_save.push(s.text)
                        }

                        # No of views for each question
                        views = page.css("div.question_stats li.view_count a span strong")
                        views.each{|v|
                                views_save.push(v.text)
                        }


                        # All the Tags
                        tags = page.css("div.topic_list_item span").select{|link| link['class'] == "name_text"}
                        tags.each{|link| tags_save.push(link.text) }

                        # puts "Tags Addition Started"

                        tags = page.css("div.topic_list_item a.topic_name")
                        tags.each{|link|
                              tags_link_save = link["href"]
                              ary = $db_list.execute "SELECT * from Topics WHERE Link = '"+ tags_link_save.to_s + "'"

                              if(ary.length.to_i == 0)
                                      $db_list.execute "INSERT INTO Topics VALUES ('"+tags_link_save.to_s+"')"
                              end
                        }

                        # puts "Tags Addition Done"


                        ques_save.each do |i|

                                # fJson = File.open(path+"/data"+id+".json","a")
                                puts i
                         #    question_hash = { :Question => i,
                         #                                :Followers => followers_final,
                         #                                :Tags => tags_save,
                         #                                :Shares => shares_ques_save[0],
                         #                                :Related_Question => related_save,
                         #                                :Users_Sharing => shares_question_names,
                         #                                :No_of_Comments => comments_ques_save[0],
                         #                                :Views => views_save[0],
                         #                                :No_of_Answers => no_of_answers_final,
                         #                                :Answers => answers_json

                         #                              }

                         #    fJson.write(JSON.pretty_generate(question_hash))
                         #    fJson.write(",\n")
                                # fJson.close

                                db.execute "INSERT INTO Questions VALUES("+universal_count.to_s+",'"+i.gsub(/[^0-9a-z.?+-_*#!@ ]/i, '')+"','"+followers_final.to_s.gsub(/[^0-9a-z.?+-_*#!@ ]/i, '')+"','"+shares_ques_save[0].to_s.gsub(/[^0-9a-z.?+-_*#!@ ]/i, '')+"','"+comments_ques_save[0].to_s.gsub(/[^0-9a-z.?+-_*#!@ ]/i, '')+"','"+views_save[0].to_s.gsub(/[^0-9a-z.?+-_*#!@ ]/i, '')+"','"+no_of_answers_final.to_s.gsub(/[^0-9a-z.?+-_*#!@ ]/i, '')+"')"

                                mutex.synchronize do
                                        $db_list.execute "INSERT INTO List VALUES ('"+link_start+"')"
                                        $questions_total.push(link_start)
                                end

                                tags_save.each do |tag|
                                        db.execute "INSERT INTO Tags VALUES("+universal_count.to_s+",'"+tag.gsub(/[^0-9a-z.?+-_*#!@ ]/i, '')+"')"
                                end

                                shares_question_names.each do |name|
                                        db.execute "INSERT INTO Shares VALUES("+universal_count.to_s+",'"+name.gsub(/[^0-9a-z.?+-_*#!@ ]/i, '')+"')"
                                end

                                related_save.each do |ques|
                                        db.execute "INSERT INTO Related_Questions VALUES("+universal_count.to_s+",'"+ques.gsub(/[^0-9a-z.?+-_*#!@ ]/i, '')+"')"
                                end

                                answers = page.css("div.answer_wrapper")
                                answers.each{ |ans|

                                        temp = nil
                                        answerers_save_name = nil
                                        upvotes_save = nil
                                        answer_text = nil
                                        timestamp_save = nil
                                        comments_save = nil
                                        shares_answer_save = nil
                                        answerers_save_link = nil
                                        temp_up = ""

                                        # Name of answerers
                                        inside = ans.css("span.feed_item_answer_user a.user")
                                        inside.each{ |name_ans|
                                                temp = name_ans.text
                                                answerers_save_name = name_ans.text
                                                answerers_save_link = name_ans["href"]
                                        }

                                        if (temp == nil)
                                                answerers_save_name = "Anonymous"
                                        end
                                        # --------------------------------------

                                        upvotes = ans.css("span.answer_voters b")
                                        upvotes.each{ |u|
                                                upvotes_save = u.text
                                        }

                                        answer_content = ans.css("div.answer_content")
                                        answer_content.each { |e|
                                                answer_text = e.text
                                        }

                                        # No of comments for each answer
                                        comments = ans.css("a.view_comments span.count")
                                        comments.each{|c|
                                                comments_save = c.text
                                        }

                                        timestamp = ans.css("div.action_item a.answer_permalink")
                                        timestamp.each{|t|
                                                timestamp_save = t.text
                                        }

                                        shares_answer = ans.css("div.action_item span.repost_count_link")
                                        shares_answer.each{|s|
                                                shares_answer_save = s.text
                                        }



                                        upvotes_sharing_people = ans.css("span.answer_voters")
                                        upvotes_sharing_people.each{|name|

                                                up_names =  name.css("a.user")
                                                up_names.each{|u|
                                                        temp_up  = temp_up + "---"+u["href"]
                                                }
                                                puts temp_up +" \n\n"
                                        }

                                        # individual_answer = {:Answerer => answerers_save_name,
                                        #                                        :Upvotes => upvotes_save,
                                        #                                        :Content => answer_text,
                                        #                                        :No_of_Comments => comments_save,
                                        #                                        :No_of_Shares => shares_answer_save,
                                        #                                        :Timestamp => timestamp_save
                                        #                                       }

                                        # answers_json.push(individual_answer)

                                        # puts answerers_save_name
                                        db.execute "INSERT INTO Answers VALUES ("+universal_count.to_s+",'"+answer_text.gsub(/[^0-9a-z.?+-_*#!@ ]/i, '')+"','"+answerers_save_name.gsub(/[^0-9a-z.?+-_*#!@ ]/i, '')+"','"+answerers_save_link.to_s+"','"+upvotes_save.to_s.gsub(/[^0-9a-z.?+-_*#!@ ]/i, '')+"','"+comments_save.to_s.gsub(/[^0-9a-z.?+-_*#!@ ]/i, '')+"','"+shares_answer_save.to_s+"','"+timestamp_save.to_s.gsub(/[^0-9a-z.?+-_*#!@ ]/i, '')+"','"+temp_up.to_s.gsub(/[^0-9a-z.?+-_*#!@ ]/i, '')+"')"

                                        # ary = db.execute "SELECT * from Users WHERE Link = '"+ answerers_save_link.to_s + "'"

                                        # if(ary.length.to_i == 0)
                                        #       db.execute "INSERT INTO Users VALUES ('"+answerers_save_link.to_s+"')"
                                        # end

                                }

                                universal_count = universal_count + 1
                                restart_browser_count = restart_browser_count + 1;
                        end

                        puts "\tSaving Question Done"

                        ques_save.clear
                        answerers_save_links.clear
                        tags_save.clear
                        related_save.clear
                        shares_ques_save.clear
                        comments_ques_save.clear
                        views_save.clear
                        answers_json.clear
                        shares_question_names.clear

                        counter = check_if_questions_are_to_be_written(questions_list, counter)

                        questions_list.shift

                        # To restart browser in case the phantomjs module takaes up lots of RAM
                        if(restart_browser_count == 500000)
                                inf_count_ = 1
                                while inf_count_ > 0
                                        begin
                                                restart_browser_count = 0
                                                b.close

                                                b = Watir::Browser.new :phantomjs

                                                b.goto 'http://www.quora.com'
                                                puts b.title
                                                b.text_field(:name => 'email').set 'jot321@gmail.com'
                                                b.text_field(:name => 'password').set 'jot968954901'
                                                sleep(3)
                                                b.send_keys :enter

                                                sleep(5)
                                                break
                                        rescue
                                                next
                                        end
                                end

                        end


                rescue => e
                        questions_list.push(link_start)
                        # questions_list.shift
                        puts e.backtrace
                        puts "There is an Exception"+id_.to_s
                        next
                end

        end

        b.close
end

$db_list = SQLite3::Database.open Dir.pwd+"/Quora_General_Data.db"
$questions_total = Array.new
$questions_total = reload_database();

#write_questions_to_load_next_to_file($questions_total)
 t1 = Thread.new{crawl(1,20,1)}
 sleep(30)
 t2 = Thread.new{crawl(21,50,2)}
 sleep(30)
 t3 = Thread.new{crawl(51,75,3)}
 sleep(30)
 t4 = Thread.new{crawl(76,100,4)}
 sleep(50)
 t5 = Thread.new{crawl(101,130,5)}
 sleep(50)
 t6 = Thread.new{crawl(131,190,6)}
print "abc"

t1.join
t2.join
t3.join
