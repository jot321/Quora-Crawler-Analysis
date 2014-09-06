import csv
import numpy
import matplotlib.pyplot as plt
import sqlite3

def plotLinearData(input, str1, str2):
	plt.plot(input)
	plt.ylabel(str1)
	plt.xlabel(str2)
	# plt.yscale('log')
	# plt.xscale('log')
	plt.show()

def noOfQuestionsPerTopics(file_obj):

	a = numpy.zeros(60000)
	b = numpy.zeros(60000)

	reader = csv.reader(file_obj)
	for row in reader:
		a[int(row[0])]  = a[int(row[0])] + 1

	for i in range(len(a)):
		b[i] = a[i]/1000;

	plotLinearData(a, 'No of Topics', 'No of Questions per Topics')

def getNoOfAnswers():

	a = numpy.zeros(3000)
	conn = sqlite3.connect('Quora_Total_Data.db')
	cursor = conn.execute("SELECT Id, No_of_Answers from Questions")

	for row in cursor:
		if(row[1] != ""):
			a[int(row[1])] = a[int(row[1])] + 1

	plotLinearData(a, 'No of Questions', 'No of Answers')

def getAnswersUpvotes():

	sum = 0
	conn = sqlite3.connect('Quora_Total_Data.db')
	cursor = conn.execute("SELECT Timestamp from Answers")	

	months = ["Jan", "Feb", "Mar", "Apr", "May" ,"Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	years = ["2010", "2011", "2012", "2013"]
	arr = {}
	
	for i in months:
		for j in years:
			arr[i+j]=0

	for row in cursor:
		if(row[0] != "" and (row[0][-4:] == "2011" or row[0][-4:] == "2012" or row[0][-4:] == "2013" or row[0][-4:] == "2010" ) ):
			month = row[0][-9:][:3]
			year = row[0][-4:]
			arr[month + year] = arr[month + year] + 1
			sum = sum + 1

	sumCumulative = 0
	dates = []
	for i in years:
		for j in months:
			sumCumulative = sumCumulative + arr[j+i]
			dates.append(sumCumulative)
			print i + "-" + j + "->" + str(arr[j+i])


	plotLinearData(dates[:46], "No of Questions", "Monthwise Distribution")


def AnswererAnalysis():

	a = numpy.zeros(1000)
	conn = sqlite3.connect('Quora_Total_Data.db')
	cursor = conn.execute("select count(Answerer) as c from Answers GROUP BY Answerer ORDER BY c DESC")

	for row in cursor:
		if(row[0] != "" and row[0] < 1000 and row[0] > 10):
			a[int(row[0])] = a[int(row[0])] + 1

	plotLinearData(a, 'X', 'Y')

def upvotes():

	conn = sqlite3.connect('Quora_Answers_With_Upvotes.db')
	
	conn2 = sqlite3.connect('Quora_Mid_User.db')
	cursor2 = conn2.execute("SELECT Name, Followers from Users")
	
	conn3 = sqlite3.connect('Quora_Temp.db')
	conn3.execute ("CREATE TABLE IF NOT EXISTS Temp (Name Text, Upvotes Text , UpvotesAnswers Text) ")

	for row2 in cursor2:

		cursor = conn.execute("SELECT Answerer, Upvotes from Answers WHERE Answerer = '" + row2[0] + "' and Upvotes != '' " )	

		upvotesSum = 0
		sum = 0
		if(cursor):
			for row in cursor:	
				up = row[1]
				up = up.replace(",", "")

				if("k" in up):
					up = up.replace("k","")
					upvotesSum += (float(up) * 1000)
					sum += 1
				else:
					upvotesSum += int(up)
					sum += 1
			
			# conn3.execute("UPDATE Users SET Upvotes = " + str(upvotesSum) + ", UpvotesAnswers = " + str(sum) + " WHERE Name = '" + row[0] + "'")
			conn3.execute("Insert into Temp (Name , Upvotes  , UpvotesAnswers ) VALUES ('" + row[0] + "','" + str(upvotesSum) + "','" + str(sum) + "')");
			conn3.commit()
			print ("UPDATE Users SET Upvotes = " + str(upvotesSum) + ", UpvotesAnswers = " + str(sum) + " WHERE Name = '" + row[0] + "'")
			print (row[0] + "\t" + str(upvotesSum) + "\t" + str(sum) + "\t" +row2[1])
			
	
	conn3.close()

def temp():
	conn = sqlite3.connect('Quora_Temp.db')
	cursor = conn.execute("SELECT * from Temp ")
	conn2 = sqlite3.connect("Quora_Mid_User.db")
	conn2.execute("ALTER TABLE Users add Upvotes TEXT");
	conn2.commit();
	conn2.execute("ALTER TABLE Users add UpvotesAnswers TEXT");
	conn2.commit();

	for row in cursor:
		conn2.execute("UPDATE Users SET Upvotes = " + row[1] + ", UpvotesAnswers = " + row[2] + " WHERE Name = '" + row[0] + "'")
		conn2.commit()

	conn2.close()	
# f = open("Topics.csv")
# csv_reader(f)  
# getAnswersUpvotes()
# getNoOfAnswers()
# AnswererAnalysis()
# upvotes()
temp()



