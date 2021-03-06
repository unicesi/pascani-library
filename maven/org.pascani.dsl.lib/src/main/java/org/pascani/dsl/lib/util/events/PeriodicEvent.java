/*
 * Copyright © 2015 Universidad Icesi
 * 
 * This file is part of the Pascani project.
 * 
 * The Pascani project is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version.
 * 
 * The Pascani project is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with The Pascani project. If not, see <http://www.gnu.org/licenses/>.
 */
package org.pascani.dsl.lib.util.events;

import static org.quartz.CronScheduleBuilder.cronSchedule;
import static org.quartz.JobBuilder.newJob;
import static org.quartz.TriggerBuilder.newTrigger;

import java.text.ParseException;
import java.util.UUID;

import org.pascani.dsl.lib.events.IntervalEvent;
import org.pascani.dsl.lib.util.CronConstant;
import org.pascani.dsl.lib.util.Exceptions;
import org.pascani.dsl.lib.util.JobScheduler;
import org.quartz.CronExpression;
import org.quartz.Job;
import org.quartz.JobDataMap;
import org.quartz.JobDetail;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
import org.quartz.Trigger;
import org.quartz.TriggerKey;

/**
 * <b>Note</b>: DSL-only intended use
 * 
 * @author Miguel Jiménez - Initial contribution and API
 */
public class PeriodicEvent extends ManagedEvent<IntervalEvent> {

	protected CronExpression expression;
	
	private String triggerKey;

	public static class InternalJob implements Job {
		@Override public void execute(JobExecutionContext context)
				throws JobExecutionException {
			JobDataMap jobData = context.getJobDetail().getJobDataMap();
			IntervalEvent event = new IntervalEvent(UUID.randomUUID(),
					jobData.getString("expression"));
			PeriodicEvent e = (PeriodicEvent) jobData.get("this");
			e.setChanged();
			e.notifyObservers(event);
		}
	}

	public PeriodicEvent(String cronExpression) throws ParseException {
		this(new CronExpression(cronExpression));
	}

	public PeriodicEvent(CronConstant cronConstant) {
		this(cronConstant.expression());
	}

	public PeriodicEvent(CronExpression cronExpression) {
		super();
		this.expression = cronExpression;
		schedule();
	}

	public void updateExpression(CronExpression newExpression) {
		this.expression = newExpression;
		unschedule();
		schedule();
	}
	
	private void schedule() {
		try {
			this.triggerKey = this.expression.getCronExpression() + System.nanoTime();
			JobDataMap jobData = new JobDataMap();
			jobData.put("expression", this.expression.getCronExpression());
			jobData.put("this", this);
			JobDetail jobDetail = newJob(InternalJob.class).usingJobData(jobData).build();
			Trigger trigger = newTrigger().startNow()
					.withIdentity(this.triggerKey)
					.withSchedule(cronSchedule(expression)).build();
			JobScheduler.schedule(jobDetail, trigger);
		} catch (Exception e) {
			Exceptions.sneakyThrow(e);
		}
	}
	
	private void unschedule() {
		try {
			JobScheduler.unschedule(TriggerKey.triggerKey(this.triggerKey));
		} catch (Exception e) {
			Exceptions.sneakyThrow(e);
		}
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see pascani.lang.util.dsl.ManagedEvent#pause()
	 */
	@Override public synchronized void pause() {
		if (isPaused())
			return;
		unschedule();
		super.pause();
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see pascani.lang.util.dsl.ManagedEvent#unpause()
	 */
	@Override public synchronized void unpause() {
		if (!isPaused())
			return;
		schedule();
		super.unpause();
	}

	public CronExpression expression() {
		return this.expression;
	}

}
