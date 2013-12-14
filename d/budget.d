module budget;

import std.datetime;
import std.math;
import std.stdio;
import std.algorithm;

struct Category {
	string name;
	Category[] children;
}

struct Persely {
	string name;
}

struct CategoryMoney {
	Category* category;
	double amount;
}

struct Saving {
	Category* category;
	double neededAmount;
	double collectedAmount;
}

struct LekotesTime {
	int months;
}

@property LekotesTime year(in double time) {
	return LekotesTime(cast(int)(time * 12 + 0.5));
}

@property LekotesTime month(in int time) {
	return LekotesTime(time);
}

unittest {
	auto t = 10.5.year;
	assert(t.months == 126);

	t = 10.month;
	assert(t.months == 10);
}

struct Lekotes {
	double amount;
	double yearInterest;
	LekotesTime lekotesTime;
	Persely* persely;

	double amountAfter(in LekotesTime time) {
		double monthInterest = (yearInterest / 12.0) / 100.0;
		double sum = amount;
		foreach(month; 0..time.months) {
			double interest = sum * monthInterest;
			sum += interest;
			writeln(sum);
		}
		return sum;
	}
}

unittest {
	Lekotes lekotes = {100, 6.5, 1.year};
	double sum = lekotes.amountAfter(12.month);
	writeln(100*1.065, ", ", sum);
	assert(sum.approxEqual(100*1.065));
}

struct Transaction {
	double amount;
	string memo;
	Category category;
	Persely persely;
	Date date;
}

struct Transactions {
	private const(Transaction)[] transactions;
	private const(Transaction)[][const(Persely)] perselyTransactions;
	private const(Transaction)[][const(Category)] categoryTransactions;
	//Transaction[Saving] perselyTransactions;

	const(Transaction)[] opSlice() const {
		return transactions;
	}

	const(Transaction)[] opIndex(in Persely p) const {
		auto retPtr = p in perselyTransactions;
		return retPtr ? *retPtr : [];
	}

	const(Transaction)[] opIndex(in Category c) const {
		auto retPtr = c in categoryTransactions;
		return retPtr ? *retPtr : [];
	}

	void add(in Transaction tx) {
		transactions ~= tx;
		perselyTransactions[tx.persely] ~= tx;
		categoryTransactions[tx.category] ~= tx;
	}
}

struct User {
	Persely[] perselyek;
	Category[] categories;
	Saving[] savings;
	Lekotes[] lekotesek;
	Transactions transactions;

	invariant() {
		foreach(ref tx; transactions[]) {
			assert(transactions[tx.persely].count(tx) == 1);
			assert(transactions[tx.category].count(tx) == 1);
		}
		foreach(persely; perselyek) {
			foreach(tx; transactions[persely]) {
				assert(transactions[].count(tx) == 1);
			}
		}
		foreach(cat; categories) {
			foreach(tx; transactions[cat]) {
				assert(transactions[].count(tx) == 1);
			}
		}
	}

	void addTransaction(in Transaction tx) {
		transactions.add(tx);
	}
}

unittest {
	Category cat = Category("TestCategory");
	Persely persely = Persely("Malac");
	User user = User([persely], [cat]);
	auto tx = Transaction(100, "teszt", cat, persely);
	user.addTransaction(tx);
	assert(user.transactions[cat].length == 1);
}


/*
void main() {
	writeln("OK");
}*/