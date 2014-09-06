import numpy
import scipy
import sqlite3
import matplotlib.pyplot as plt

def calculateDataPoints(dbName, color):
	conn = sqlite3.connect(dbName)
	cursor = conn.execute("SELECT Questions , Upvotes, UpvotesAnswers from Users")

	yQ = []
	xQ = []
	for row in cursor:
		q = str(row[0]).replace(",", "")
		a = str(row[1]).replace(",", "")
		b = str(row[2]).replace(",", "")

		
		print a + "-" + b +"-" + q

		if(q is not "" and a is not "" and b is not "" and b != "None" and a != "None" and q is not "None" and int(q) < 1000  ):
			if(b != None and float(b) !=0):
				if(float(b) > 7 and float(a)/float(b) < 1000):
					yQ.append(float(q))
					xQ.append(float(a)/float(b))
			
	conn.close()
	plot(xQ, yQ, color)

def calculateDataPointsBinary(dbName, color):
	conn = sqlite3.connect(dbName)
	cursor = conn.execute("SELECT Questions , Answers from Users")

	yQ = []
	xQ = []
	for row in cursor:
		q = str(row[0]).replace(",", "")
		a = str(row[1]).replace(",", "")
		# b = str(row[2]).replace(",", "")

		

		if(q is not "" and a is not "" and a != "None" and q is not "None" and int(q) < 1000  ):
			yQ.append(float(q))
			xQ.append(float(a))
	
	conn.close()
	plot(xQ, yQ, color)

def plot(xQ, yQ, colour):
	plt.scatter(xQ,yQ, color = colour)
	# plt.title("Web traffic over the last month")
	plt.xlabel("No of Avg Upvotes")
	plt.ylabel("No of Questions")
	# plt.xticks([w*7*24 for w in range(10)],
	# ['week %i'%w for w in range(10)])
	plt.yscale('log')
	plt.xscale('log')

	# plt.autoscale(tight=True)
	plt.grid()
	


calculateDataPointsBinary("Quora_Super_User_Data.db", "red");	
calculateDataPointsBinary("Quora_Mid_User.db", "blue");	
plt.show()